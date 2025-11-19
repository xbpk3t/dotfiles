{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.n8n;
  containerName = "n8n";
  stateDir = "/var/lib/${containerName}";
in {
  # https://mynixos.com/nixpkgs/options/services.n8n
  # https://mynixos.com/nixpkgs/package/n8n
  # [基于 n8n 的开源自动化：以滴答清单同步 Notion 为例 ｜ 少数派会员 π+Prime](https://sspai.com/prime/story/automation-n8n)

  options.modules.services.n8n = {
    enable = mkEnableOption "n8n automation platform (container)";

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "n8n");
      default = null;
      description = "Expose n8n via the shared reverse proxy.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra container attributes merged on top of defaults.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0750 root root -"
      ];

      virtualisation.oci-containers.containers.${containerName} = mkMerge [
        {
          autoStart = false;
          image = "n8nio/n8n";
          environment = {
            LETSENCRYPT_EMAIL = "";
            LETSENCRYPT_HOST = "";
            N8N_BASIC_AUTH_ACTIVE = "true";
            N8N_BASIC_AUTH_PASSWORD = "{PASSWORD}";
            N8N_BASIC_AUTH_USER = "";
            N8N_EDITOR_BASE_URL = "https://";
            N8N_PORT = "5678";
            VIRTUAL_HOST = "";
          };
          volumes = [
            "${stateDir}:/home/node/.n8n:rw"
            #            "/mnt/multimedia/n8n:/home/node/.n8n:rw"
          ];
          ports = [
            "5678:5678/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=n8n"
            #            "--network=n8n_default"
          ];
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.n8n";
        ingress = cfg.ingress;
      })
    )
  ];
}
