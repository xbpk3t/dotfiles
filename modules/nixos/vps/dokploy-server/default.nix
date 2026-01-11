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

    # [2026-01-11] 之前是systemd里跑docker run，改为更NixOS的方案
    # 用更 declarative 的 oci-containers 管 Traefik，行为等价于 docker run
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.dokploy-traefik = {
      image = "traefik:v3.6.1";
      autoStart = true;

      # 关键点：必须加入 dokploy overlay 网络，否则动态路由回源会走 overlay IP 而不可达（导致504）
      # 这里用 extraOptions 是因为 oci-containers schema 没有 networks 选项
      extraOptions = ["--network=dokploy-network"];

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml"
        "/etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic"
      ];

      # 保持与现有行为一致：对外提供 HTTP/HTTPS/HTTP3 入口
      ports = [
        "80:80/tcp"
        "443:443/tcp"
        "443:443/udp"
      ];
    };

    # 先确保 Swarm + overlay network 已创建，否则容器会因 network not found 启动失败
    # oci-containers 生成的 unit 名为 docker-<container>.service
    systemd.services."docker-dokploy-traefik" = {
      after = ["docker.service" "dokploy-swarm.service"];
      requires = ["docker.service" "dokploy-swarm.service"];
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
