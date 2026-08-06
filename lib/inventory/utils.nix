{
  lib,
  inventoryData,
}:
let
  nodesOrEmpty = inventory: if inventory == null then { } else inventory;
  inventory = nodesOrEmpty inventoryData;
  groupOrEmpty = name: inventory.${name} or { };
  # Why：inventory 是纯数据（分组内节点结构），可能同时提供 primaryIp/ip/ips/ssh.host。
  # What：按优先级挑一个”主机地址”作为部署/连接默认值。
  primaryHostForNode =
    name: node:
    let
      candidates = [
        (node.primaryIp or null)
        (node.ip or null)
        (if node ? ips && node.ips != [ ] then builtins.head node.ips else null)
        (node.ssh.host or null)
        name
      ];
    in
    lib.findFirst (v: v != null) null candidates;
  normalizeSingboxNode =
    name: node:
    let
      inherit (node) singbox;
    in
    singbox
    // {
      hostName = node.hostName or name;
      server = singbox.server or primaryHostForNode name node;
    };
in
{
  inherit primaryHostForNode;
  # 分组入口（简化调用）：mylib.inventory.<group>
  "nixos-avf" = groupOrEmpty "nixos-avf";
  "nixos-vps" = groupOrEmpty "nixos-vps";
  "nixos-homelab" = groupOrEmpty "nixos-homelab";
  "nixos-ws" = groupOrEmpty "nixos-ws";
  "nixos-usb" = groupOrEmpty "nixos-usb";
  "macos-ws" = groupOrEmpty "macos-ws";
  "sm-vps" = groupOrEmpty "sm-vps";

  singboxForHost =
    inventory: hostName:
    let
      nodes = nodesOrEmpty inventory;
      node = nodes.${hostName};
    in
    normalizeSingboxNode hostName node;

  deployRsNode =
    {
      name,
      node,
      nixosConfiguration,
      deployLib,
      defaultSshUser ? "root",
      defaultSshPort ? null,
      remoteBuild ? true,
    }:
    let
      ssh = node.ssh or { };
      host = ssh.host or (primaryHostForNode name node);
      sshUser = ssh.user or defaultSshUser;
      sshPort = ssh.port or defaultSshPort;
      extraOpts = ssh.opts or [ ];
      sshOpts =
        extraOpts
        ++ lib.optionals (sshPort != null) [
          "-p"
          (toString sshPort)
        ];
    in
    {
      # What：部署目标地址（IP/域名/别名）。
      # Why：由 inventory 的 primaryIp/ip/ips/ssh.host 统一推导，避免重复填部署字段。
      hostname = host;
      # What：SSH 用户名。
      # Why：默认 root，允许每个节点覆盖（node.ssh.user）。
      inherit sshUser;
      # What：额外 SSH 参数（如端口）。
      # Why：deploy-rs 没有独立的 sshPort 字段，只能通过 sshOpts 传递。
      inherit sshOpts;
      # What：是否在远端构建。
      # Why：与 Colmena 的 buildOnTarget 行为一致，避免本地负载。
      inherit remoteBuild;
      profiles.system = {
        # What：远端激活该 profile 的用户。
        # Why：NixOS 系统级激活必须以 root 执行。
        user = "root";
        # What：NixOS 系统 profile 的激活路径（系统 closure）。
        # Why：deploy-rs 通过 deployLib.activate.nixos 生成可执行的激活入口。
        path = deployLib.activate.nixos nixosConfiguration;
      };
    };

  # sm-vps 平行轨（非 NixOS）的 deploy-rs 节点构造。
  # 与 deployRsNode 的区别：
  #   - 两个 profile：`system`（system-manager）与 `home`（standalone HM）
  #   - `system` 用 activate.custom 包 system-manager-engine 的 activate（需 root → user = "root"）
  #   - `home` 用 activate.home-manager（以 SSH 用户激活用户 profile）
  #   - 默认 remoteBuild = false（R3：本机构建 + nix copy；跳板/目标机通常无本地 build 收益）
  # 设计约束（与主航道隔离）：
  #   - 不修改 deployRsNode 的 activate.nixos 语义
  #   - system profile 的 user 固定为 root（sm 激活写 /etc、systemd、/var/lib）
  #     → deploy-rs 在 sshUser != root 时自动用 `sudo <user>` 包装（容器内 luck 有 NOPASSWD sudo）
  #   - profilesOrder 默认先 system 后 home（先建系统态再收敛用户态）
  deploySmHmNode =
    {
      name,
      node,
      # system-manager toplevel（config.build.toplevel）
      systemToplevel,
      # standalone HM 的 activationPackage（homeConfigurations.<name>.activationPackage）
      homeActivationPackage,
      deployLib,
      defaultSshUser ? "luck",
      defaultSshPort ? null,
      remoteBuild ? false,
      profilesOrder ? [
        "system"
        "home"
      ],
    }:
    let
      ssh = node.ssh or { };
      host = ssh.host or (primaryHostForNode name node);
      sshUser = ssh.user or defaultSshUser;
      sshPort = ssh.port or defaultSshPort;
      extraOpts = ssh.opts or [ ];
      sshOpts =
        extraOpts
        ++ lib.optionals (sshPort != null) [
          "-p"
          (toString sshPort)
        ];
      # sm 引擎激活：deploy-rs 先 nix-env --set 把 $PROFILE 指向 toplevel，
      # 再运行 activate 脚本；引擎读 $PROFILE 下的 etc/services 描述并落地。
      # 注意：sm 引擎本身不依赖 nix 命令（activate 只跑 preActivationAssertions + 应用状态）。
      smActivate = "$PROFILE/bin/system-manager-engine --store-path $PROFILE activate";
    in
    {
      # What：部署目标地址（IP/域名/别名）。
      # Why：与 deployRsNode 一致，由 inventory 的 ssh.host/primaryIp 推导。
      hostname = host;
      inherit sshUser sshOpts remoteBuild;
      profiles = {
        # 系统轨：sm 激活必须 root（写 /etc、systemd、/var/lib/system-manager）。
        system = {
          user = "root";
          path = deployLib.activate.custom systemToplevel smActivate;
        };
        # 用户轨：standalone HM 以 SSH 用户（luck）激活用户 profile。
        home = {
          user = sshUser;
          path = deployLib.activate.home-manager homeActivationPackage;
        };
      };
      inherit profilesOrder;
    };
}
