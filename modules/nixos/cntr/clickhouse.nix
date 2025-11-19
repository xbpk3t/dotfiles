{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.clickhouse;
  containerName = "ck";
  dataDir = "/var/lib/${containerName}";
  configDir = "/var/lib/${containerName}/config";
  usersDir = "/var/lib/${containerName}/users";
in {
  options.modules.services.clickhouse = {
    enable = mkEnableOption "ClickHouse server (container)";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "ClickHouse");
      default = null;
      description = "Expose the HTTP port via the shared reverse proxy.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra container attributes.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0750 root root -"
        "d ${configDir} 0750 root root -"
        "d ${usersDir} 0750 root root -"
      ];

      virtualisation.oci-containers.containers.${containerName} = mkMerge [
        {
          autoStart = false;
          image = "clickhouse/clickhouse-server";
          volumes = [
            "${configDir}:/etc/clickhouse-server/config.d:rw"
            "${dataDir}:/var/lib/clickhouse:rw"
            "${usersDir}:/etc/clickhouse-server/users.d:rw"
            #              "/home/luck/Desktop/dotfiles/manifests/docker/ck/config:/etc/clickhouse-server/config.d:rw"
            #              "/home/luck/Desktop/dotfiles/manifests/docker/ck/data:/var/lib/clickhouse:rw"
            #              "/home/luck/Desktop/dotfiles/manifests/docker/ck/users:/etc/clickhouse-server/users.d:rw"
          ];
          ports = [
            "8123:8123/tcp"
            "9000:9000/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=clickhouse"
            #            "--network=ck_default"
          ];
          environment = {
            CLICKHOUSE_USER = "gotomicro";
            CLICKHOUSE_PASSWORD = "clickhouse";
            CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT = "1";
          };
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.clickhouse";
        ingress = cfg.ingress;
      })
    )
  ];
}
