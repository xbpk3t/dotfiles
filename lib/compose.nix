{lib}: let
  inherit
    (lib)
    attrByPath
    mapAttrs
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  ensureAttrPath = secretName:
    if builtins.isList secretName
    then secretName
    else [secretName];
in {
  mkManagedComposeModule = {
    name,
    composeFile,
    description ? "${name} stack managed via nix-managed-docker-compose",
    ingressLabel ? name,
    enableIngress ? true,
    secretEnvDefault ? null,
  }: {
    config,
    mylib,
    ...
  }: let
    cfg = config.modules.services.${name};
    ingressCfg = cfg.ingress or null;
    secretOption =
      if secretEnvDefault == null
      then {}
      else {
        secretEnv = mkOption {
          type = types.attrsOf (types.either types.str (types.listOf types.str));
          default = secretEnvDefault;
          description = "Map compose environment keys to entries in config.sops.secrets.";
        };
      };
    secretFileMap =
      if secretEnvDefault == null
      then {}
      else let
        secretPath = secretName:
          attrByPath
          (ensureAttrPath secretName ++ ["path"])
          (throw "Secret ${builtins.toString secretName} 未在 sops.secrets 中定义")
          config.sops.secrets;
      in
        mapAttrs (_: secretPath) cfg.secretEnv;
    ingressOptions =
      if enableIngress
      then {
        ingress = mkOption {
          type = types.nullOr (mylib.ingressOption ingressLabel);
          default = null;
          description = "Expose ${ingressLabel} through the shared reverse proxy.";
        };
      }
      else {};
    ingressConfig =
      if enableIngress
      then
        mkIf (mylib.ingressEnabled ingressCfg)
        (mylib.mkReverseProxyIngress {
          modulePath = "modules.services.${name}";
          ingress = ingressCfg;
        })
      else {};
  in {
    options.modules.services.${name} =
      {
        enable = mkEnableOption description;
        environment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Literal substitutions passed to the compose file.";
        };
      }
      // ingressOptions
      // secretOption;

    config = mkMerge [
      (mkIf cfg.enable {
        services.managedDockerCompose = {
          enable = mkDefault true;
          backend = "docker";
          projects.${name} = (
            {
              inherit composeFile;
              substitutions = cfg.environment;
            }
            // (
              if secretEnvDefault == null
              then {}
              else {substitutionsFromFiles = secretFileMap;}
            )
          );
        };
      })
      ingressConfig
    ];
  };
}
