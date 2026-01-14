{
  lib,
  mylib,
  genSpecialArgs,
  modules,
  args,
  targets,
  name,
  system ? (modules.system or args.system or "x86_64-linux"),
  baseTags ? [name],
  extraTags ? [],
}: let
  sanitize = host:
    lib.strings.sanitizeDerivationName (
      lib.strings.replaceStrings ["." ":" "/"] ["-" "-" "-"] host
    );

  mkNodeName = host:
    if builtins.length targets == 1
    then name
    else "${name}-${sanitize host}";

  commonArgs = modules // args // {inherit system genSpecialArgs;};

  # 从所有 colmena targets 统一派生 singbox 服务器清单：
  # - 只要 target.meta.singbox 存在，就加入列表
  # - 每个节点都会拿到同一份完整列表，便于客户端直连/切换
  mkSingboxServer = target: let
    meta = target.meta or {};
    singboxMeta = meta.singbox or null;
  in
    if singboxMeta == null
    then null
    else let
      nodeId = mylib.node.nodeId {
        roleName = name;
        targetHost = target.host;
      };
      hostMeta = mylib.node.hostMeta {
        roleName = name;
        targetHost = target.host;
        inherit nodeId;
        meta = meta;
      };
    in {
      server = target.host;
      port = singboxMeta.port or 8443;
      label = singboxMeta.label or nodeId;
      hostName = hostMeta.hostName;
    };

  singboxServersAll = lib.lists.filter (s: s != null) (map mkSingboxServer targets);

  mkNixosNode = target: let
    nodeName = mkNodeName target.host;
    # 通过 colmena 的目标主机生成唯一 nodeId，并派生 host 元信息
    nodeId = mylib.node.nodeId {
      roleName = name;
      targetHost = target.host;
    };
    hostMeta = mylib.node.hostMeta {
      roleName = name;
      targetHost = target.host;
      inherit nodeId;
      meta = target.meta or {};
    };
    # singbox 服务器清单由顶层统一派生，确保每个节点拿到同一份列表
    singboxServers = singboxServersAll;
  in {
    ${nodeName} = mylib.nixosSystem (
      commonArgs
      // {
        # 将 nodeId/hostMeta/singboxServers 注入 specialArgs，确保 nixos-rebuild 也能拿到一致的标识
        specialArgs =
          (genSpecialArgs system)
          // {
            inherit nodeId hostMeta singboxServers;
          };
      }
    );
  };

  mkColmenaNode = target: let
    nodeName = mkNodeName target.host;
    # 同上：每个 colmena 节点都注入 nodeId/hostMeta，避免多机 hostname 重复导致冲突
    nodeId = mylib.node.nodeId {
      roleName = name;
      targetHost = target.host;
    };
    hostMeta = mylib.node.hostMeta {
      roleName = name;
      targetHost = target.host;
      inherit nodeId;
      meta = target.meta or {};
    };
    user = target.user or "root";
    tags =
      baseTags
      ++ extraTags
      ++ (target.tags or []);
    # singbox 服务器清单由顶层统一派生，确保每个节点拿到同一份列表
    singboxServers = singboxServersAll;
  in {
    ${nodeName} = mylib.colmenaSystem (
      commonArgs
      // {
        inherit genSpecialArgs tags;
        # 给 colmena 节点注入 nodeId/hostMeta/singboxServers，供各模块生成唯一域名/标识
        specialArgs =
          (genSpecialArgs system)
          // {
            inherit nodeId hostMeta singboxServers;
          };
        # colmena 本身不一定会透传 specialArgs 到 NixOS 模块系统，
        # 这里用 extraModules 显式写入 _module.args，保证 nodeId/hostMeta/singboxServers 可用。
        extraModules = [
          {
            _module.args.nodeId = nodeId;
            _module.args.hostMeta = hostMeta;
            _module.args.singboxServers = singboxServers;
          }
        ];
        targetHost = target.host;
        targetPort = target.port or null;
        targetUser = user;
        ssh-user = user;
      }
    );
  };
in {
  nixosConfigurations = lib.attrsets.mergeAttrsList (map mkNixosNode targets);
  colmena = lib.attrsets.mergeAttrsList (map mkColmenaNode targets);
}
