{
  myvars,
  pkgs,
  ...
}: {
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
    oci-containers = {
      backend = "docker";
      containers = {
        nginx = {
          image = "nginx:latest";
          ports = ["80:80"];
          autoStart = false;
        };
        redis = {
          image = "redis:alpine";
          autoStart = false;
        };

        beszel = {
          image = "henrygd/beszel:latest";
          environment = {
            "TZ" = "Asia/Shanghai";
          };
          #            volumes = [
          #              "/home/luck/Desktop/dotfiles/manifests/docker/beszel/beszel_data:/beszel_data:rw"
          #            ];
          ports = [
            "8090:8090/tcp"
          ];
          log-driver = "journald";
          #          extraOptions = [
          #            "--add-host=host.docker.internal:host-gateway"
          #            "--network-alias=beszel"
          #            "--network=beszel_default"
          #          ];
          autoStart = false;
        };

        # https://hub.docker.com/r/szabis/iventoy
        # https://github.com/garybowers/iventoy_docker
        # iVentoy（包括这个Docker镜像）在装机时确实需要通过LAN（有线网）来工作，因为它是一个基于PXE的网络启动工具，主要依赖局域网内的DHCP和TFTP服务来引导客户端从服务器上获取ISO镜像并启动安装。
        # 为什么必须插网线？
        #
        #PXE引导机制：iVentoy服务器（运行在Docker中）和目标机器（装机机）必须在同一个局域网（LAN）内。目标机通过网络卡（NIC）从iVentoy服务器请求引导文件和ISO数据。如果没有网线连接，目标机就无法接入LAN，也就无法PXE启动。
        #没有WiFi支持：PXE标准主要针对有线网络（Ethernet），无线WiFi在BIOS/UEFI的PXE模式下支持有限或不稳定，尤其在装机初期（还没安装驱动）。如果你用WiFi适配器，它可能需要额外的驱动，但iVentoy的ISO挂载和数据传输仍需稳定的LAN连接。
        #ISO传输：你把ISO存到iVentoy服务器上，目标机通过网络“挂载”它作为虚拟光驱。如果断网（无网线），传输就会失败。

        # 简单来说，因为在装机时，还没有wifi，所以必须要插着网线走LAN，才能从另一台机器上拿到这个iventoy上存着的iso
        iventoy = {
          autoStart = false;

          image = "szabis/iventoy:latest";
          environment = {
            "AUTO_START_PXE" = "true";
          };
          volumes = [
            "/path/to/data:/opt/iventoy/data:rw"
            "/path/to/iso:/opt/iventoy/iso:rw"
            "/path/to/log:/opt/iventoy/log:rw"
            "/path/to/user:/opt/iventoy/user:rw"
          ];
          ports = [
            "67:67/udp"
            "69:69/udp"
            "10809:10809/tcp"
            "16000:16000/tcp"
            "26000:26000/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network=host"
            "--privileged"
          ];
        };

        # rsshub.lucc.dev {
        #	encode gzip
        #	tls yyzw@live.com
        #	reverse_proxy /* http://127.0.0.1:1200
        #}
        #
        #mon.lucc.dev {
        #        encode gzip
        #        tls yyzw@live.com
        #        reverse_proxy /* http://127.0.0.1:8090
        #}
        caddy = {
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
        };

        n8n = {
          autoStart = false;

          image = "n8nio/n8n";
          environment = {
            "LETSENCRYPT_EMAIL" = "";
            "LETSENCRYPT_HOST" = "";
            "N8N_BASIC_AUTH_ACTIVE" = "true";
            "N8N_BASIC_AUTH_PASSWORD" = "{PASSWORD}";
            "N8N_BASIC_AUTH_USER" = "";
            "N8N_EDITOR_BASE_URL" = "https://";
            "N8N_PORT" = "5678";
            "VIRTUAL_HOST" = "";
          };
          volumes = [
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
        };

        portainer = {
          autoStart = false;

          image = "portainer/portainer-ce:2.26.0-alpine";
          volumes = [
            #            "/home/luck/Desktop/dotfiles/manifests/docker/portainer/data:/data:rw"
            #            "/var/run/docker.sock:/var/run/docker.sock:rw"
          ];
          ports = [
            "9000:9000/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=portainer"
            #            "--network=portainer_default"
          ];
        };

        qinglong = {
          autoStart = false;

          image = "whyour/qinglong:latest";
          environment = {
            "QlBaseUrl" = "/";
          };
          volumes = [
            #            "/home/luck/Desktop/dotfiles/manifests/docker/qinglong/data:/ql/data:rw"
          ];
          ports = [
            "5700:5700/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=web"
            #            "--network=qinglong_default"
          ];
        };

        # Ensure the `./data` directory is writable by UID 1001 (the user that runs the container):
        #   mkdir -p data
        #   sudo chown -R 1001:1001 data
        openlist = {
          autoStart = false;
          image = "openlistteam/openlist:latest";
          volumes = [
            #            "/home/luck/Desktop/dotfiles/manifests/docker/openlist/data:/opt/openlist/data:rw"
            #            "/home/luck/Downloads:/home/luck/Downloads:ro"
            #            "/home/luck/Downloads/vscs-video:/home/luck/Downloads/vscs-video:ro"
          ];
          ports = [
            "5244:5244/tcp"
          ];
          log-driver = "journald";
          #          extraOptions = [
          #            "--network-alias=openlist"
          #            "--network=openlist_default"
          #          ];
        };

        watchtower = {
          autoStart = false;

          image = "containrrr/watchtower:latest";
          environment = {
            "TZ" = "Asia/Shanghai";
            "WATCHTOWER_CLEANUP" = "true";
          };
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:rw"
          ];
          cmd = ["--interval" "3600" "--cleanup"];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=watchtower"
            #            "--network=watchtower_default"
          ];
        };

        ck = {
          autoStart = false;

          image = "clickhouse/clickhouse-server";
          volumes = [
            #              "/home/luck/Desktop/dotfiles/manifests/docker/ck/config:/etc/clickhouse-server/config.d:rw"
            #              "/home/luck/Desktop/dotfiles/manifests/docker/ck/data:/var/lib/clickhouse:rw"
            #              "/home/luck/Desktop/dotfiles/manifests/docker/ck/users:/etc/clickhouse-server/users.d:rw"
          ];
          ports = [
            "8123:8123/tcp"
            "9000:9000/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=clickhouse"
            #            "--network=ck_default"
          ];
          environment = {
            CLICKHOUSE_USER = "gotomicro";
            CLICKHOUSE_PASSWORD = "clickhouse";
            CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT = "1";
          };
        };
      };
    };

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

  # https://mynixos.com/nixpkgs/option/containers
  containers = {
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
