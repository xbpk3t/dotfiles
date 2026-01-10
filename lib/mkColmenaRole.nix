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

  commonArgs = modules // args // {inherit system;};

  mkNixosNode = target: let
    nodeName = mkNodeName target.host;
    # 通过 colmena 的目标主机生成唯一 nodeId，
    # 供 NixOS 模块在不依赖 hostname 的情况下确定本机身份。
    nodeId = mylib.nodeId {
      roleName = name;
      targetHost = target.host;
    };
  in {
    ${nodeName} = mylib.nixosSystem (
      commonArgs
      // {
        # 将 nodeId 注入 specialArgs，确保 nixos-rebuild 也能拿到一致的标识
        specialArgs = (genSpecialArgs system) // {inherit nodeId;};
      }
    );
  };

  mkColmenaNode = target: let
    nodeName = mkNodeName target.host;
    # 同上：每个 colmena 节点都注入 nodeId，避免多机 hostname 重复导致冲突
    nodeId = mylib.nodeId {
      roleName = name;
      targetHost = target.host;
    };
    user = target.user or "root";
    tags =
      baseTags
      ++ extraTags
      ++ (target.tags or []);
  in {
    ${nodeName} = mylib.colmenaSystem (
      commonArgs
      // {
        inherit genSpecialArgs tags;
        # 给 colmena 节点注入 nodeId，供各模块生成唯一域名/标识
        specialArgs = (genSpecialArgs system) // {inherit nodeId;};
        # colmena 本身不一定会透传 specialArgs 到 NixOS 模块系统，
        # 这里用 extraModules 显式写入 _module.args，保证 nodeId 可用。
        extraModules = [
          {_module.args.nodeId = nodeId;}
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
