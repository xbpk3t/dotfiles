{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  isDesktop = config.modules.roles.isDesktop;
in {
  ###################################################################################
  #
  #  Virtualisation - Libvirt(QEMU/KVM) / Docker / LXD / WayDroid
  #
  ###################################################################################

  # Enable nested virtualization, required by security containers and nested vm.
  # This should be set per host in /hosts, not here.
  #
  ## For AMD CPU, add "kvm-amd" to kernelModules.
  # boot.kernelModules = ["kvm-amd"];
  # boot.extraModprobeConfig = "options kvm_amd nested=1";  # for amd cpu
  #
  ## For Intel CPU, add "kvm-intel" to kernelModules.
  # boot.kernelModules = ["kvm-intel"];
  # boot.extraModprobeConfig = "options kvm_intel nested=1"; # for intel cpu

  # https://get.docker.com/

  boot.kernelModules = ["vfio-pci"];

  # https://mynixos.com/nixpkgs/options/virtualisation
  # https://mynixos.com/nixpkgs/options/virtualisation.docker
  # https://mynixos.com/nixpkgs/options/virtualisation.podman
  virtualisation = {
    podman.enable = false;
    docker = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      # dockerCompat = true;

      #      rootless = {
      #        enable = true;
      #        setSocketVariable = true; # expose DOCKER_HOST/PODMAN_SOCKET for the user session
      #      };

      daemon = {
        settings = {
          registry-mirrors = [
            "https://dockerproxy.com"
            "https://docker.m.daocloud.io"
            "https://hub-mirror.c.163.com"
            "https://mirror.ccs.tencentyun.com"
          ];
        };
      };

      # Required for containers under podman-compose to be able to talk to each other.
      # defaultNetwork.settings.dns_enabled = true;
      # Periodically prune Podman resources
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = ["--all"];
      };
    };

    # https://mynixos.com/nixpkgs/options/virtualisation.oci-containers
    oci-containers.backend = "docker";

    # Usage: https://wiki.nixos.org/wiki/Waydroid
    # waydroid.enable = true;

    # libvirtd = {
    #   enable = true;
    #   # hanging this option to false may cause file permission issues for existing guests.
    #   # To fix these, manually change ownership of affected files in /var/lib/libvirt/qemu to qemu-libvirtd.
    #   qemu.runAsRoot = true;
    # };

    # lxd.enable = true;
  };

  # 只在Desktop下添加 nixos container. 否则在VPS里（即使不启用）也会占用磁盘
  # https://mynixos.com/nixpkgs/option/containers
  containers = mkIf isDesktop {
    nixos-minimal = {
      # 配置为不要自启，需要 sudo nixos-container start nixos-minimal 手动启动
      autoStart = false;
      ephemeral = false;
      privateNetwork = true;
      hostAddress = "10.254.0.1";
      localAddress = "10.254.0.2";
      specialArgs = {
        inherit myvars;
      };
      config = {
        imports = [
          (pkgs.path + "/nixos/modules/profiles/minimal.nix")
        ];

        networking.hostName = "nixos-minimal";
        networking.firewall.allowedTCPPorts = [22];

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "prohibit-password";
            PasswordAuthentication = false;
          };
        };

        users.users.root.openssh.authorizedKeys.keys =
          myvars.mainSshAuthorizedKeys or [];

        system.stateVersion = "24.11";
      };
    };

    # https://nixos.wiki/wiki/NixOS_Containers
    #    nextcloud = {
    #      autoStart = false;
    #      privateNetwork = true;
    #      hostAddress = "192.168.100.10";
    #      localAddress = "192.168.100.11";
    #      hostAddress6 = "fc00::1";
    #      localAddress6 = "fc00::2";
    #      config = {
    #        pkgs,
    #        lib,
    #        ...
    #      }: {
    #        services.nextcloud = {
    #          enable = true;
    #          package = pkgs.nextcloud28;
    #          hostName = "localhost";
    #          config.adminpassFile = "${pkgs.writeText "adminpass" "test123"}"; # DON'T DO THIS IN PRODUCTION - the password file will be world-readable in the Nix Store!
    #        };
    #
    #        system.stateVersion = "23.11";
    #
    #        networking = {
    #          firewall = {
    #            enable = true;
    #            allowedTCPPorts = [80];
    #          };
    #          # Use systemd-resolved inside the container
    #          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    #          useHostResolvConf = lib.mkForce false;
    #        };
    #
    #        services.resolved.enable = true;
    #      };
    #    };
  };

  environment.systemPackages = with pkgs; [
    # This script is used to install the arm translation layer for waydroid
    # so that we can install arm apks on x86_64 waydroid
    #
    # https://github.com/casualsnek/waydroid_script
    # https://github.com/AtaraxiaSjel/nur/tree/master/pkgs/waydroid-script
    # https://wiki.archlinux.org/title/Waydroid#ARM_Apps_Incompatible
    # nur-ataraxiasjel.packages.${pkgs.system}.waydroid-script

    # Need to add [File (in the menu bar) -> Add connection] when start for the first time
    # virt-manager

    # QEMU/KVM(HostCpuOnly), provides:
    #   qemu-storage-daemon qemu-edid qemu-ga
    #   qemu-pr-helper qemu-nbd elf2dmp qemu-img qemu-io
    #   qemu-kvm qemu-system-x86_64 qemu-system-aarch64 qemu-system-i386
    qemu_kvm

    # Install QEMU(other architectures), provides:
    #   ......
    #   qemu-loongarch64 qemu-system-loongarch64
    #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32  qemu-system-riscv32
    #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
    #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
    #   ......
    qemu
  ];
}
