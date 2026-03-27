{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ms.colima;
  isDarwin = pkgs.stdenv.isDarwin;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
  useVz = isDarwin && isAarch64;
in {
  options.modules.ms.colima = with lib; {
    enable = mkEnableOption "Colima container runtime service";
  };

  config = lib.mkIf cfg.enable {
    # Colima 本身负责创建和管理 docker context，这里只负责声明式启用默认 profile。
    programs.docker-cli.enable = true;

    # https://mynixos.com/home-manager/options/services.colima
    # https://mynixos.com/nixpkgs/package/colima
    services.colima = {
      enable = true;

      profiles.default = {
        isActive = true;
        isService = true;
        setDockerHost = true;

        # https://mynixos.com/home-manager/option/services.colima.profiles.%3Cname%3E.settings
        settings = {
          # https://raw.githubusercontent.com/Omochice/dotfiles/refs/heads/main/config/colima/default/colima.yaml
          cpu = 4;
          disk = 200;
          memory = 16;

          # 跟随 host arch，避免在 x86_64 NixOS 上被错误固定成 aarch64。
          # 如果后续要在 Apple Silicon 上专门跑 x86_64 guest，再单独建 profile。
          arch = "host";

          runtime = "docker";
          autoActivate = true;
          hostname = "colima";

          kubernetes = {
            enabled = false;

            # Kubernetes 关闭时，不需要把 version / k3sArgs 固定写死。
            # version = "v1.33.3+k3s1";
            # k3sArgs = [ "--disable=traefik" ];
          };

          docker = {};

          # `vz` 只适合 Apple Silicon macOS；其它平台统一退回 qemu。
          vmType =
            if useVz
            then "vz"
            else "qemu";

          portForwarder = "ssh";

          # Rosetta 只在 Apple Silicon + VZ 下有效，其它平台必须关闭。
          rosetta = useVz;

          # 保留 binfmt，方便在 guest 内跑 foreign-arch containers。
          binfmt = true;
          nestedVirtualization = false;

          # `virtiofs` 主要给 VZ 用；qemu 下显式退回更通用的 sshfs。
          mountType =
            if useVz
            then "virtiofs"
            else "sshfs";

          forwardAgent = false;

          # 这些项要么和平台强相关，要么在当前配置里没有明确收益，先注释掉。
          # modelRunner = "";
          # mountInotify = true;
          # sshConfig = false;
          # rootDisk = 20;
          # network = {
          #   # `address = true` 适合需要稳定 guest IP 的场景，但会引入额外网络假设。
          #   address = true;
          #   preferredRoute = false;
          # };
          # mounts = [ ];
          # provision = [ ];
          # env = { };
        };
      };
    };
  };
}
