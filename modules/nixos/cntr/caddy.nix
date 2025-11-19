{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.services.caddy;
  containerName = "caddy";
in {
  # rsshub.lucc.dev {
  # 	encode gzip
  # 	tls yyzw@live.com
  # 	reverse_proxy /* http://127.0.0.1:1200
  # }
  #
  # mon.lucc.dev {
  #         encode gzip
  #         tls yyzw@live.com
  #         reverse_proxy /* http://127.0.0.1:8090
  # }

  options.modules.services.caddy = {
    enable = mkEnableOption "Caddy reverse proxy (container)";

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra container attributes.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.${containerName} = mkMerge [
      {
        autoStart = false;
        image = "caddy:alpine";
        volumes = [
          #              "/home/luck/Desktop/dotfiles/manifests/docker/caddy/Caddyfile:/etc/caddy/Caddyfile:rw"
          #              "/home/luck/Desktop/dotfiles/manifests/docker/caddy/config:/config:rw"
          #              "/home/luck/Desktop/dotfiles/manifests/docker/caddy/data:/data:rw"
          #              "/home/luck/Desktop/dotfiles/manifests/docker/caddy/site:/srv:rw"
        ];
        ports = [
          "80:80/tcp"
          "80:80/udp"
          "443:443/tcp"
          "443:443/udp"
          "1200/tcp"
          "8090/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          #            "--cap-add=NET_ADMIN"
          #            "--network=host"
        ];
      }
      cfg.settings
    ];
  };
}
