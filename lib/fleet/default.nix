# Fleet registry: node-keyed view over hosts/**/meta.nix.
#
# 节点发现规则见下方 scanTop：顶层目录有 meta.nix 是单节点，否则是 group，
# 子目录里的 meta.nix 是节点；节点名由相对路径派生。
#
# 这里是“跨机拓扑”的唯一入口：
#   - nodes / tailnetNodes：按节点名索引的扁平表
#   - singboxServers：所有发布 singbox 能力的节点
#   - nezha：唯一的 hub 及其派生地址
#   - deployRsNode / deploySmHmNode：deploy-rs 节点构造器
#   - checks：可在 nix-unit 里逐条断言的不变量
#
# 单机身份/配置不要加到这里；它们属于 hosts/<name>/。
{ lib }:
let
  hostsDir = ../../hosts;

  isDir = type: type == "directory";

  topEntries = builtins.readDir hostsDir;

  # 节点名 = hosts/ 下的相对路径，把 "/" 换成 "-"：
  #   hosts/nixos-vps/dev      -> nixos-vps-dev
  #   hosts/macos-ws           -> macos-ws
  #   hosts/sm-vps/tc          -> sm-vps-tc
  # meta.nix 不再写 hostName；这里统一派生，避免第二份身份源。
  scanNode =
    name: path:
    let
      meta = import (path + "/meta.nix");
      forbidden = lib.filter (field: meta ? ${field}) [
        "hostName"
        "name"
        "path"
      ];
    in
    assert lib.assertMsg (forbidden == [ ])
      "fleet: '${name}' meta.nix must not declare ${lib.concatStringsSep ", " forbidden} (derived from the hosts path)";
    meta
    // {
      inherit name path;
      hostName = name;
    };

  # 顶层目录两种形态：
  #   - 有 meta.nix       -> 单节点（目录名即节点名）
  #   - 无 meta.nix       -> group；子目录里每个 meta.nix 是一个节点
  # `_base` / 其他 `_` 前缀目录不参与发现（顶层目录与 group 内子目录同一规则）。
  scanTop =
    topName:
    let
      topPath = hostsDir + "/${topName}";
      entries = builtins.readDir topPath;
      children = lib.filterAttrs (
        childName: childType:
        isDir childType
        && !(lib.hasPrefix "_" childName)
        && builtins.pathExists (topPath + "/${childName}/meta.nix")
      ) entries;
      childNodes = lib.mapAttrs' (
        childName: _:
        lib.nameValuePair "${topName}-${childName}" (
          scanNode "${topName}-${childName}" (topPath + "/${childName}")
        )
      ) children;
    in
    if entries ? "meta.nix" then
      assert lib.assertMsg (children == { })
        "fleet: '${topName}' has meta.nix and child node meta.nix; a directory must be either a node or a group";
      {
        ${topName} = {
          ${topName} = scanNode topName topPath;
        };
      }
    else
      assert lib.assertMsg (
        children != { }
      ) "fleet: group '${topName}' has no meta.nix and no child node meta.nix";
      {
        ${topName} = childNodes;
      };

  groups = lib.foldl' (acc: topName: acc // (scanTop topName)) { } (
    lib.filter (name: isDir topEntries.${name} && !(lib.hasPrefix "_" name)) (lib.attrNames topEntries)
  );

  # 节点名必须全局唯一：group 子目录派生的 "<group>-<node>" 与顶层单节点目录可能撞名，
  # foldl' 的 `//` 会静默只留一个 → 直接报错，避免 host 从 outputs 里悄无声息消失。
  allNodes = lib.foldl' (
    acc: group:
    let
      duplicates = lib.filter (nodeName: acc ? ${nodeName}) (lib.attrNames group);
    in
    if duplicates != [ ] then
      throw "fleet: duplicate node name(s): ${lib.concatStringsSep ", " duplicates}"
    else
      acc // group
  ) { } (lib.attrValues groups);

  # 按优先级挑一个“主机地址”作为部署/连接默认值。
  # tailnet 优先：sshd 统一经 tailnet 访问，公网 IP 只保留给 DNS/代理等对外服务。
  primaryHostForNode = name: node: node.tailscale.ip or node.ssh.host or name;

  tailnetNodes = lib.filterAttrs (_: node: node ? tailscale && node.tailscale ? ip) allNodes;

  # DERP 节点必须声明非空 domain/dnsKey 和 publicIpv4；否则 ACME/DNS 会漂移。
  derperNodeComplete =
    node:
    (node.derper.domain or "") != ""
    && (node.derper.dnsKey or "") != ""
    && (node.publicIpv4 or null) != null;

  # 发布给 TF DNS 的 DERP 节点视图。这里不静默过滤不完整节点：
  # 生成物漏掉一条记录会让 Terraform 删除已有 DNS record；直接 throw 更安全。
  derperNodes = lib.mapAttrs (
    name: node:
    if derperNodeComplete node then
      node
    else
      throw "fleet: incomplete derper meta for '${name}' (need derper.domain, derper.dnsKey, publicIpv4)"
  ) (lib.filterAttrs (_: node: node ? derper) allNodes);

  # 发布给 client 的 singbox server 视图：补 hostName 和 server fallback，
  # 保持 fleet API 的形状稳定；server 缺失时的最终契约仍由 checks 兜底。
  singboxServers = lib.filter (s: s != null) (
    lib.attrsets.mapAttrsToList (
      name: node:
      if node ? singbox then
        node.singbox
        // {
          hostName = node.hostName or name;
          server = node.singbox.server or (primaryHostForNode name node);
        }
      else
        null
    ) allNodes
  );

  # Nezha: exactly one node may declare `nezha.hub = true`. Agents derive
  # their dashboard address from that node, so the hub address stays in the
  # fleet registry instead of being duplicated in host modules.
  nezhaHub =
    let
      hubs = lib.filter (node: node.nezha.hub or false) (lib.attrValues allNodes);
    in
    if hubs == [ ] then
      null
    else if lib.length hubs > 1 then
      throw "fleet: multiple nodes declare nezha.hub = true"
    else
      builtins.head hubs;

  # Hub 端口的默认值只在这里维护；host 模块和 Nezha 模块都从这里取。
  nezhaDefaultPort = 8008;

  nezhaServer =
    if nezhaHub == null then
      throw "fleet: no node declares nezha.hub = true"
    else
      "${primaryHostForNode nezhaHub.hostName nezhaHub}:${
        toString (nezhaHub.nezha.port or nezhaDefaultPort)
      }";

  nodeList = lib.attrValues allNodes;
  every = pred: lib.all pred nodeList;

  # 不变量：值全部是布尔，nix-unit 直接消费；键以 test- 开头。
  # 注意：hostName 由 scanNode 从路径派生（并在 meta 自带 hostName 时直接报错），
  # 不再单列 "hostName == node key" 测试——那是构造保证的，写出来只会是永远为真的假测试。
  checks = {
    "test-kind-present" = every (node: node ? kind);

    "test-system-present" = every (node: node ? system);

    "test-stateVersion-non-empty" = every (node: (node.stateVersion or "") != "");

    "test-tailnet-ip-unique" =
      let
        ips = lib.map (node: node.tailscale.ip) (lib.attrValues tailnetNodes);
      in
      lib.length ips == lib.length (lib.unique ips);

    # DERP 节点必须声明非空 domain/dnsKey 和 publicIpv4；
    # 否则 derperNodes 会直接 throw，这个 check 让 nix-unit 也能提前报红。
    "test-derper-node-complete" = every (node: !(node ? derper) || derperNodeComplete node);

    "test-derper-domain-unique" =
      let
        domains = map (node: node.derper.domain) (
          lib.filter (node: node ? derper && node.derper ? domain) nodeList
        );
      in
      lib.length domains == lib.length (lib.unique domains);

    # dnsKey 是 Terraform records 的 for_each key；重复会静默覆盖其中一条。
    "test-derper-dns-key-unique" =
      let
        keys = map (node: node.derper.dnsKey) (
          lib.filter (node: node ? derper && node.derper ? dnsKey) nodeList
        );
      in
      lib.length keys == lib.length (lib.unique keys);

    "test-nezha-hub-at-most-one" =
      lib.length (lib.filter (node: node.nezha.hub or false) nodeList) <= 1;

    "test-singbox-server-address" = every (node: !(node ? singbox) || node.singbox ? server);

    # 每个节点必须有可寻址的 tailscale.ip 或 ssh.host，避免 primaryHostForNode 回退到节点名。
    "test-node-addressable" = every (
      node: (node.tailscale.ip or null) != null || (node.ssh.host or null) != null
    );

    # SSH 登录用户只由 ssh.user 决定；deploy.sshUser 不是有效契约。
    "test-no-deploy-ssh-user" = every (node: (node.deploy.sshUser or null) == null);

    # 用户身份是 flake globals.identity，不允许回流到 per-node meta。
    "test-no-per-node-identity" = every (node: !(node ? user) && !(node ? time) && !(node ? editor));
  };

  # 所有 deploy-rs 节点共享的 SSH 目标解析（hostname / sshUser / sshOpts）。
  # NixOS / darwin / sm 的差异只在 profiles 与 rollback 策略，留在各构造器里。
  deployTarget =
    {
      name,
      node,
      defaultSshUser,
      defaultSshPort ? null,
      remoteBuild ? true,
    }:
    let
      ssh = node.ssh or { };
      sshPort = ssh.port or defaultSshPort;
    in
    {
      # What：部署目标地址（IP/域名/别名）。
      # Why：由 fleet registry 的 ssh.host/tailscale.ip 统一推导，避免重复填部署字段。
      hostname = ssh.host or (primaryHostForNode name node);
      # What：SSH 用户名。
      # Why：默认值由平台构造器给出，允许每个节点覆盖（node.ssh.user）。
      sshUser = ssh.user or defaultSshUser;
      # What：额外 SSH 参数（如端口）。
      # Why：deploy-rs 没有独立的 sshPort 字段，只能通过 sshOpts 传递。
      sshOpts =
        (ssh.opts or [ ])
        ++ lib.optionals (sshPort != null) [
          "-p"
          (toString sshPort)
        ];
      # What：是否在远端构建。
      # Why：与 Colmena 的 buildOnTarget 行为一致，避免本地负载。
      inherit remoteBuild;
    };

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
    deployTarget {
      inherit
        name
        node
        defaultSshUser
        defaultSshPort
        remoteBuild
        ;
    }
    // {
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
      # sm 引擎激活：deploy-rs 先 nix-env --set 把 $PROFILE 指向 toplevel，
      # 再运行 activate 脚本；引擎读 $PROFILE 下的 etc/services 描述并落地。
      # 关键坑（Phase 8 实测）：
      # 1. --store-path 是 activate 子命令的参数（sm 1.1.0 语法），不是顶层参数。
      # 2. $PROFILE 是 /nix/var/nix/profiles/system 的 symlink 链（system -> system-1-link ->
      #    /nix/store/...），sm 引擎 TryFrom<PathBuf> 遇到「相对 symlink 目标」会报
      #    "not in nix store: system-1-link"。必须 readlink -f 解析到真实 store 路径。
      # 引擎本身不依赖 nix 命令（activate 只跑 preActivationAssertions + 应用状态）。
      smActivate = "REAL=\$(readlink -f \$PROFILE) && \$PROFILE/bin/system-manager-engine activate --store-path \$REAL";

      target = deployTarget {
        inherit
          name
          node
          defaultSshUser
          defaultSshPort
          remoteBuild
          ;
      };
    in
    target
    // {
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
          user = target.sshUser;
          path = deployLib.activate.home-manager homeActivationPackage;
        };
      };
      inherit profilesOrder;
    };
in
{
  inherit
    deployTarget
    primaryHostForNode
    tailnetNodes
    derperNodes
    singboxServers
    deployRsNode
    deploySmHmNode
    checks
    ;

  # 扁平化所有 group 的节点（节点名全局唯一，可直接查找）。
  nodes = allNodes;

  nezha = {
    hub = nezhaHub;
    server = nezhaServer;
    defaultPort = nezhaDefaultPort;
  };
}
