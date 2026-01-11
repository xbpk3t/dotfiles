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
    # 注意 nix-dokploy 是写到 /var/lib/dokploy，然后 symlink 到 /etc/dokploy，我们这里直接写到 /etc 即可。减少心智负担。
    systemd.tmpfiles.rules = [
      "d /etc/dokploy 0777 root root -"
      # 这是 Traefik 配置目录，通常由 root 管理即可。
      "d /etc/dokploy/traefik 0755 root root -"
      # Traefik 容器只需要写入 dynamic/acme.json，本身目录无需可写。
      "d /etc/dokploy/traefik/dynamic 0755 root root -"
      # 如未来把证书文件单独存放，可再按需调整目录权限。
      "d /etc/dokploy/traefik/dynamic/certificates 0755 root root -"
      # Traefik 以容器方式运行（root），ACME 证书写入由容器完成
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

    # Traefik（容器方式），与 Dokploy 动态路由机制保持一致
    systemd.services.dokploy-traefik = {
      description = "Dokploy Traefik container";
      after = ["docker.service" "dokploy-swarm.service"];
      requires = ["docker.service" "dokploy-swarm.service"];
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if docker ps -a --format '{{.Names}}' | grep -q '^dokploy-traefik$'; then
          echo "Starting existing Traefik container..."
          docker start dokploy-traefik
        else
          echo "Creating and starting Traefik container..."
          docker run -d \
            --name dokploy-traefik \
            --network dokploy-network \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml \
            -v /etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic \
            -p 80:80/tcp \
            -p 443:443/tcp \
            -p 443:443/udp \
            traefik:v3.6.1
        fi
      '';
      serviceConfig.ExecStop = "${pkgs.docker}/bin/docker stop dokploy-traefik || true";
      serviceConfig.ExecStopPost = "${pkgs.docker}/bin/docker rm dokploy-traefik || true";
      wantedBy = ["multi-user.target"];
    };

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
