{
  config,
  lib,
  inputs,
  ...
}:
# Declarative Dokploy deployment via the nix-dokploy module.
let
  cfg = config.modules.homelab.dokploy;
in {
  options.modules.homelab.dokploy.enable = lib.mkEnableOption "Enable Dokploy stack (via nix-dokploy)";

  imports = [inputs.nix-dokploy.nixosModules.default];

  config = lib.mkIf cfg.enable {
    # systemctl restart dokploy-stack.service
    # systemctl list-dependencies dokploy-*
    # systemctl status dokploy*
    # docker stack ps dokploy


    # 几点注意：
    # 1、启动时可能缺少 ingress 这个 network，需要用 docker network create --ingress --driver overlay ingress 添加该network
    # 2、卸载时，注意需要移除掉 /var/lib/dokploy 里的数据
    services.dokploy = {
      enable = true;
      # Keep the default upstream binding; override in host if you want to hide it behind Traefik only.
      port = "3000:3000";

      # https://github.com/el-kurto/nix-dokploy/issues/5
      # 通过 symlink 到 /etc/dokploy 来保证跟 Dokploy本身的path兼容
      # Store data under /var/lib to avoid writing into /etc directly; keep default password as required upstream.
      dataDir = "/var/lib/dokploy";

      # Swarm advertise address: prefer private IP for single-node homelab.
      swarm = {
        advertiseAddress = "private";
        autoRecreate = false;
      };
    };

    # Ensure Docker pre-req from nix-dokploy assertions.
    virtualisation.docker.enable = lib.mkDefault true;
    virtualisation.docker.daemon.settings.live-restore = lib.mkDefault false;

    # Open ports for Traefik if firewall is enabled on host layer.
    networking.firewall.allowedTCPPorts = lib.mkAfter [80 443];
    networking.firewall.allowedUDPPorts = lib.mkAfter [443];
  };
}
