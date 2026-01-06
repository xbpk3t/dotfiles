{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.dokploy-server;
in {
  # https://github.com/Dokploy/dokploy/blob/canary/packages/server/src/setup/server-setup.ts
  options.services.dokploy-server = {
    enable = mkEnableOption "Dokploy server stack";
  };

  ##### Config #####
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # https://mynixos.com/nixpkgs/package/rclone
      rclone
      # https://mynixos.com/nixpkgs/package/nixpacks
      nixpacks
      # https://mynixos.com/nixpkgs/package/pack
      # https://github.com/buildpacks/pack
      pack

      # 没有该pkg
      # railpack
    ];

    # /etc/dokploy structure & permissions
    # 注意 nix-dokploy 是写到 /var/lib/dokploy，然后 symlink 到 /etc/dokploy，我们这里直接写到/etc即可。减少心智负担。
    systemd.tmpfiles.rules = [
      "d /etc/dokploy 0777 root root -"
      "d /etc/dokploy/traefik 0755 root root -"
      "d /etc/dokploy/traefik/dynamic 0755 root root -"
      "d /etc/dokploy/traefik/dynamic/certificates 0755 root root -"
      "f /etc/dokploy/traefik/dynamic/acme.json 0600 root root -"
      "d /etc/dokploy/logs 0755 root root -"
      "d /etc/dokploy/applications 0755 root root -"
      "d /etc/dokploy/compose 0755 root root -"
      "d /etc/dokploy/ssh 0700 root root -"
      "d /etc/dokploy/monitoring 0755 root root -"
      "d /etc/dokploy/registry 0755 root root -"
      "d /etc/dokploy/schedules 0755 root root -"
      "d /etc/dokploy/volume-backups 0755 root root -"
    ];

    # Render Traefik configs into /etc/dokploy
    environment.etc."dokploy/traefik/traefik.yml".text = builtins.readFile ./traefik.yml;
    environment.etc."dokploy/traefik/dynamic/middlewares.yml".text = builtins.readFile ./middlewares.yml;

    # Traefik (native service, not container)
    # 这里有三个方案
    # 1、不做容器，直接用 services.traefik
    # 2、参考 nix-dokploy/nix-dokploy.nix 里面对于 traefik 的处理
    # 3、直接用类似 compose2nix 把 compose做成nix化。转成 virtualisation.oci-containers。
    # https://mynixos.com/nixpkgs/options/services.traefik
    services.traefik = {
      enable = true;
      # https://mynixos.com/nixpkgs/package/traefik
      package = pkgs.traefik;
      staticConfigFile = "/etc/dokploy/traefik/traefik.yml";
      dynamicConfigFile = "/etc/dokploy/traefik/dynamic/middlewares.yml";
    };

    # Ensure Traefik can talk to Docker
    users.users.traefik.extraGroups = ["docker"];
    systemd.services.traefik.wants = ["dokploy-swarm.service"];
    systemd.services.traefik.after = ["dokploy-swarm.service"];

    # Swarm init + overlay network (idempotent)
    systemd.services.dokploy-swarm = {
      description = "Init Docker Swarm and dokploy overlay network";
      after = ["docker.service" "docker.socket"];
      wants = ["docker.service"];
      # 否则会报错 docker: command not found
      path = [
        pkgs.docker
        pkgs.iproute2
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = builtins.readFile ./swarm-init.sh;
      wantedBy = ["multi-user.target"];
    };

    networking.firewall.allowedTCPPorts = [80 443];
    networking.firewall.allowedUDPPorts = [443];
  };
}
