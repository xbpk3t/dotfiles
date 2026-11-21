{
  config,
  lib,
  userMeta,
  ...
}:
let
  inherit (lib) mkIf mkMerge optionals;
  inherit (userMeta) username;
  cfg = config.modules.kernel.vm;
in
{
  options.modules.kernel.vm = {
    enable = lib.mkEnableOption "virtualisation baseline (docker / podman / libvirt)";

    docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the Docker daemon. Hosts that should not run it can disable
        this without affecting the rest of the virtualisation baseline.
      '';
    };

    forwardFilter = {
      enable = lib.mkEnableOption "forward filtering for container/VM traffic";

      extraAllowedDestinations = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "100.66.22.92/32" ];
        description = ''
          Destinations explicitly allowed through the forwarding filter.
          Use this only for service IPs that containers/VMs must reach;
          RFC1918, tailnet and link-local destinations are denied by default.
        '';
      };
    };
  };

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

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "vfio-pci" ];

    # 容器/VM forwarding 硬化（opt-in per host）。
    # 默认拒绝转发到 RFC1918 / tailnet / link-local；只放行容器出公网、
    # 容器互通和 host 显式登记的 service IP。需要 nftables backend，
    # 因为 networking.firewall.filterForward 只在该 backend 下生效。
    networking = lib.mkIf cfg.forwardFilter.enable {
      nftables.enable = true;
      firewall = {
        filterForward = true;
        extraForwardRules = ''
          # 容器/VM 互通（docker/podman/libvirt bridge、Docker 自定义 br-*、NixOS container ve-*）
          iifname { "docker0", "podman0", "virbr0" } oifname { "docker0", "podman0", "virbr0" } accept
          iifname "br-*" oifname "br-*" accept
          iifname "ve-*" oifname "ve-*" accept

          # 容器/VM 出公网：只放行目的地不在 RFC1918/tailnet/link-local 的流量
          iifname { "docker0", "podman0", "virbr0" } ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16 } accept
          iifname { "docker0", "podman0", "virbr0" } ip6 daddr != { fc00::/7, fe80::/10, fd7a:115c:a1e0::/48 } accept
          iifname "br-*" ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16 } accept
          iifname "br-*" ip6 daddr != { fc00::/7, fe80::/10, fd7a:115c:a1e0::/48 } accept
          iifname "ve-*" ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16 } accept
          iifname "ve-*" ip6 daddr != { fc00::/7, fe80::/10, fd7a:115c:a1e0::/48 } accept

          # host 级显式 service IP 例外（覆盖所有容器/VM bridge）
          ${lib.concatMapStringsSep "\n" (
            cidr:
            "iifname { \"docker0\", \"podman0\", \"virbr0\" } ip daddr ${cidr} accept\n"
            + "iifname \"br-*\" ip daddr ${cidr} accept\n"
            + "iifname \"ve-*\" ip daddr ${cidr} accept"
          ) cfg.forwardFilter.extraAllowedDestinations}
        '';
      };
    };

    # https://mynixos.com/nixpkgs/options/virtualisation
    # https://mynixos.com/nixpkgs/options/virtualisation.docker
    virtualisation = {
      podman.enable = false;
      docker = {
        # mkDefault：若 host 定义 oci-containers，nixpkgs 会按需把 Docker
        # 打开；不能用普通赋值，否则 docker.enable=false + containers 会
        # 变成 defined-multiple-times 的 hard eval conflict。
        enable = lib.mkDefault cfg.docker.enable;
        # Create a `docker` alias for podman, to use it as a drop-in replacement
        # dockerCompat = true;

        #      rootless = {
        #        enable = true;
        #        setSocketVariable = true; # expose DOCKER_HOST/PODMAN_SOCKET for the user session
        #      };

        daemon = {
          settings = {
            # 明确写死 journald，和当前实际行为一致；容器日志受 journald
            # SystemMaxUse=1G 约束，不依赖 Docker 自己的 json-file 轮转。
            log-driver = "journald";
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
          flags = [ "--all" ];
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

    # Service-scoped user/group wiring
    users.groups = mkMerge [
      (mkIf config.virtualisation.docker.enable { docker = { }; })
      (mkIf config.virtualisation.podman.enable { podman = { }; })
      (mkIf config.virtualisation.libvirtd.enable { libvirtd = { }; })
    ];

    users.users."${username}".extraGroups =
      optionals config.virtualisation.docker.enable [ "docker" ]
      ++ optionals config.virtualisation.podman.enable [ "podman" ]
      ++ optionals config.virtualisation.libvirtd.enable [ "libvirtd" ];
  };

  # 只在桌面模块中定义 containers，避免 VPS 场景占用磁盘

  #  environment.systemPackages = with pkgs; [
  #    # This script is used to install the arm translation layer for waydroid
  #    # so that we can install arm apks on x86_64 waydroid
  #    #
  #    # nur-ataraxiasjel.packages.${pkgs.system}.waydroid-script
  #
  #    # Need to add [File (in the menu bar) -> Add connection] when start for the first time
  #    # virt-manager
  #
  #    # QEMU/KVM(HostCpuOnly), provides:
  #    #   qemu-storage-daemon qemu-edid qemu-ga
  #    #   qemu-pr-helper qemu-nbd elf2dmp qemu-img qemu-io
  #    #   qemu-kvm qemu-system-x86_64 qemu-system-aarch64 qemu-system-i386
  #    qemu_kvm
  #
  #    # Install QEMU(other architectures), provides:
  #    #   ......
  #    #   qemu-loongarch64 qemu-system-loongarch64
  #    #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32  qemu-system-riscv32
  #    #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
  #    #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
  #    #   ......
  #    qemu
  #  ];
}
