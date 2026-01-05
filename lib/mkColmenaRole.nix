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
  in {
    ${nodeName} = mylib.nixosSystem (
      commonArgs
      // {
        genSpecialArgs = genSpecialArgs;
      }
    );
  };

  mkColmenaNode = target: let
    nodeName = mkNodeName target.host;
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
