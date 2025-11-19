{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.pgsql;
in {
  # https://mynixos.com/nixpkgs/options/services.postgresql

  options.modules.services.pgsql = {
    enable = mkEnableOption "Local PostgreSQL service for internal apps";

    package = mkOption {
      type = types.package;
      default = pkgs.postgresql_16;
      description = "PostgreSQL package to run.";
    };

    dataDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Override services.postgresql.dataDir; use default when null.";
    };

    ensureDatabases = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Databases to ensure exist.";
    };

    ensureUsers = mkOption {
      type = types.listOf types.attrs;
      default = [];
      example = [
        {
          name = "miniflux";
          ensureDBOwnership = true;
        }
      ];
      description = "User definitions passed to services.postgresql.ensureUsers.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        enableTCPIP = false;
        authentication = ''
          local all all peer
        '';
      };
      description = "Pass-through options merged into services.postgresql.* (except enable, package, dataDir, ensure*).";
    };
  };

  config = mkIf cfg.enable {
    services.postgresql = mkMerge [
      {
        enable = true;
        package = cfg.package;
        ensureDatabases = cfg.ensureDatabases;
        ensureUsers = cfg.ensureUsers;
        enableTCPIP = mkDefault false;
        authentication = mkAfter ''
          local   miniflux   miniflux   trust
        '';
      }
      (mkIf (cfg.dataDir != null) {
        dataDir = cfg.dataDir;
      })
      cfg.settings
    ];

    environment.systemPackages = [cfg.package];
  };
}
