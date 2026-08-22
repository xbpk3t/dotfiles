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
  #   - 默认 remoteBuild = true（与 deployRsNode 对齐：在目标机构建，Mac 零闭包下载。
  #     对抗验证：deploy-rs remote_build 用 nix copy -s --derivation + nix build --store ssh-ng://，
  #     本地 store 仅增量 eval 产物。R3 旧决策（false）是为容器跳板时代，真机应走 remote_build。）
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
      remoteBuild ? true,
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
      # 关键坑（Phase 8 实测）：
      # 1. --store-path 是 activate 子命令的参数（sm 1.1.0 语法），不是顶层参数。
      # 2. $PROFILE 是 /nix/var/nix/profiles/system 的 symlink 链（system -> system-1-link ->
      #    /nix/store/...），sm 引擎 TryFrom<PathBuf> 遇到「相对 symlink 目标」会报
      #    "not in nix store: system-1-link"。必须 readlink -f 解析到真实 store 路径。
      # 引擎本身不依赖 nix 命令（activate 只跑 preActivationAssertions + 应用状态）。
      smActivate = "REAL=\$(readlink -f \$PROFILE) && \$PROFILE/bin/system-manager-engine activate --store-path \$REAL";
    in
    {
      # What：部署目标地址（IP/域名/别名）。
      # Why：与 deployRsNode 一致，由 inventory 的 ssh.host/primaryIp 推导。
      hostname = host;
      inherit sshUser sshOpts remoteBuild;
      # magic rollback：deploy-rs 0.1.0 的 canary 确认机制有确认竞态 bug——
      # home-manager 激活成功（远端已删 canary）后确认命令再删一次会失败并整节点
      # 回滚（实测：Activation succeeded → rm canary No such file → 误回滚）。
      # 关闭它：sm 激活失败本来就是报错（不静默半挂），home 激活幂等可重试；
      # 相比"激活成功被误回滚"，"失败不自动回滚"的代价更小（留手动重试）。
      # 若未来 deploy-rs 修了 canary 竞态，可考虑重开（deploy-rs confirmTimeout 单位=秒）。
      magicRollback = false;
      confirmTimeout = 600;
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
