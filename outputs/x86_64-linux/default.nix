{
  lib,
  inputs,
  mylib,
  myvars,
  ...
} @ args: let
  inherit (inputs) haumea;

  # Contains all the flake outputs of this system architecture.
  # Filter out reserved names that haumea cannot handle
  filteredInputs = builtins.removeAttrs args ["self" "super" "root"];
  data = haumea.lib.load {
    src = ./src;
    inputs = filteredInputs;
  };
  # nix file names is redundant, so we remove it.
  dataWithoutPaths = builtins.attrValues data;

  colmenaProfiles = lib.attrsets.mergeAttrsList (
    map (it: it.colmenaProfiles or {}) dataWithoutPaths
  );

  colmenaTargets = myvars.networking.colmenaTargets or {};

  mkNodeName = name: hosts: host:
    if builtins.length hosts == 1
    then name
    else let
      sanitizedHost = lib.strings.sanitizeDerivationName (
        lib.strings.replaceStrings ["." ":" "/"] ["-" "-" "-"] host
      );
    in "${name}-${sanitizedHost}";

  mkNodes = name: group: let
    profile = colmenaProfiles.${name} or null;
    hosts = group.targetHosts or [];
    hostList =
      if lib.isList hosts
      then hosts
      else [hosts];
    defaultUser = profile.defaultTargetUser or "root";
  in
    if profile == null || hostList == []
    then {}
    else let
      nodeAttrs = host: let
        nodeName = mkNodeName name hostList host;
      in {
        ${nodeName} = mylib.colmenaSystem {
          inherit inputs lib myvars;
          system = profile.system;
          nixos-modules = profile."nixos-modules";
          home-modules = profile."home-modules" or [];
          genSpecialArgs = profile.genSpecialArgs;
          targetHost = host;
          targetUser = group.targetUser or defaultUser;
          targetPort = group.targetPort or null;
        };
      };
    in
      lib.attrsets.mergeAttrsList (map nodeAttrs hostList);

  colmenaNodes = lib.attrsets.mergeAttrsList (
    lib.attrsets.mapAttrsToList mkNodes colmenaTargets
  );

  # Merge all the machine's data into a single attribute set.
  outputs = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or {}) dataWithoutPaths
    );

    colmena = colmenaNodes;
  };
in
  outputs
  // {
    inherit data; # for debugging purposes

    evalTests = {};
  }
