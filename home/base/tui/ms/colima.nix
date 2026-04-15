{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ms.colima;
in {
  options.modules.ms.colima = with lib; {
    enable = mkEnableOption "Colima container runtime service";
  };

  config = lib.mkIf cfg.enable {
    # [2026-04-14] 注意两点：
    ## 1、注意这里用YAML而非nix来写，为了保证复用。另外需要注意 这里用 nix跟 launchd启动，没有必然关系。也不建议直接用 launchd启动，因为没必要开机自启这么个VM以及这堆docker服务。
    ## 2、Colima 在 colima start（默认行为）时，总是会尝试把配置写回 ~/.colima/default/colima.yaml，所以无论我们用 YAML还是nix，都需要 colima start --save-config=false 才能正常启动，否则会因为无论如何我们都用哪种方案，都会因为 colima 默认要写回配置，而 symlink 指向不可写的 nix store，导致报错
    home.file.".colima/default/colima.yaml" = {
      source = ./colima.yaml;
      force = true;
    };

    # https://mynixos.com/home-manager/options/services.colima
    # https://mynixos.com/nixpkgs/package/colima
    services.colima = {
      # 只有在 mac，才有必要用 colima，在 linux下没必要，所以这么设置
      enable = pkgs.stdenv.isDarwin;

      #      profiles.default = {
      #        isActive = true;
      #        isService = true;
      #        setDockerHost = true;
      #
      #        # https://mynixos.com/home-manager/option/services.colima.profiles.%3Cname%3E.settings
      #        settings = {
      #          # https://raw.githubusercontent.com/Omochice/dotfiles/refs/heads/main/config/colima/default/colima.yaml
      #          cpu = 4;
      #          disk = 200;
      #          memory = 16;
      #
      #          # 跟随 host arch，避免在 x86_64 NixOS 上被错误固定成 aarch64。
      #          # 如果后续要在 Apple Silicon 上专门跑 x86_64 guest，再单独建 profile。
      #          arch = "host";
      #
      #          runtime = "docker";
      #          autoActivate = true;
      #          hostname = "colima";
      #
      #          kubernetes = {
      #            enabled = false;
      #
      #            # Kubernetes 关闭时，不需要把 version / k3sArgs 固定写死。
      #            # version = "v1.33.3+k3s1";
      #            # k3sArgs = [ "--disable=traefik" ];
      #          };
      #
      #          docker = {};
      #
      #          # `vz` 只适合 Apple Silicon macOS；其它平台统一退回 qemu。
      #          vmType =
      #            if useVz
      #            then "vz"
      #            else "qemu";
      #
      #          portForwarder = "ssh";
      #
      #          # Rosetta 只在 Apple Silicon + VZ 下有效，其它平台必须关闭。
      #          rosetta = useVz;
      #
      #          # 保留 binfmt，方便在 guest 内跑 foreign-arch containers。
      #          binfmt = true;
      #          nestedVirtualization = false;
      #
      #          # `virtiofs` 主要给 VZ 用；qemu 下显式退回更通用的 sshfs。
      #          mountType =
      #            if useVz
      #            then "virtiofs"
      #            else "sshfs";
      #
      #          forwardAgent = false;
      #
      #          # 这些项要么和平台强相关，要么在当前配置里没有明确收益，先注释掉。
      #          # modelRunner = "";
      #          # mountInotify = true;
      #          # sshConfig = false;
      #          # rootDisk = 20;
      #          # network = {
      #          #   # `address = true` 适合需要稳定 guest IP 的场景，但会引入额外网络假设。
      #          #   address = true;
      #          #   preferredRoute = false;
      #          # };
      #          # mounts = [ ];
      #          # provision = [ ];
      #          # env = { };
      #        };
      #      };
    };
  };
}
