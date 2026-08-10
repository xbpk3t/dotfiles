{
  config,
  lib,
  ...
}: let
  inherit (config.lib.topology) mkInternet mkRouter mkConnection;
  icon = name: ./assets/topology-icons/${name}.svg;
in {
  # 全局拓扑定义：声明网络与外部设备；
  # 主机节点信息由 nix-topology 从 nixosConfigurations 自动提取
  # （见 outputs/default.nix 的 topology.modules 注入）。
  #
  # 参考 TheMaxMur/NixOS-Configuration 的写法：
  #   mkInternet / mkRouter / mkConnection
  # 让 README 的拓扑图能看出真实链路（Internet → VPS/家庭路由 → 各设备）。
  #
  # 注意：nixos-avf / nixos-ws / nixos-homelab / nixos-vps 等 NixOS 主机
  # 由 nixosConfigurations 自动提取；这里只显式定义网络、虚拟节点，
  # 以及不在 NixOS 配置里的设备（macOS / nix-on-droid / sm-vps）。
  networks = {
    tailnet = {
      name = "Tailnet";
      # Tailscale 网络（100.x）
      cidrv4 = "100.0.0.0/8";
    };
    lan = {
      name = "Home LAN";
      cidrv4 = "192.168.0.0/16";
    };
    wan = {
      name = "WAN (Internet)";
    };
  };

  nodes = {
    # —— 自动提取的 NixOS 主机：补接口定义（host 用 NetworkManager/DHCP，无静态接口）——
    # 注意：这些节点由 nixosConfigurations 自动提取，这里只补 interfaces，
    # 不会与自动字段冲突（原节点无 interfaces）。
    nixos-ws = {
      interfaces = {
        eth0 = { network = "lan"; };
        tailscale0 = { network = "tailnet"; };
      };
    };
    nixos-homelab = {
      interfaces = {
        eth0 = { network = "lan"; };
        tailscale0 = { network = "tailnet"; };
      };
    };
    nixos-vps-dev = {
      interfaces = {
        ens3 = { network = "wan"; };
        tailscale0 = { network = "tailnet"; };
      };
    };
    nixos-vps-svc = {
      interfaces = {
        ens3 = { network = "wan"; };
        tailscale0 = { network = "tailnet"; };
      };
    };

    # —— 互联网节点：连接所有公网出口 ——
    internet = mkInternet {
      connections = [
        (mkConnection "nixos-vps-dev" "ens3")
        (mkConnection "nixos-vps-svc" "ens3")
        (mkConnection "sm-vps" "eth0")
      ];
    };

    # —— 家庭路由（虚拟节点，把 LAN 设备收拢）——
    router = mkRouter "Home Router" {
      info = "Router (NAT)";
      image = icon "router";

      interfaceGroups = [
        ["wan1"]
        ["eth1"]
      ];

      interfaces = {
        eth1 = {
          network = "lan";
        };
        wan1 = {
          network = "wan";
        };
      };

      connections = {
        eth1 = [
          (mkConnection "nixos-ws" "eth0")
          (mkConnection "macos-ws" "en0")
          (mkConnection "nixos-usb" "eth0")
        ];
        wan1 = mkConnection "internet" "*";
      };
    };

    # —— 家庭设备（显示名带 emoji，直接 attrset 而非 mkDevice）——
    macos-ws = {
      name = "🍎 Mac Workstation";
      deviceType = lib.mkForce "laptop";
      hardware = {
        info = "Apple Silicon MacBook";
        image = icon "laptop";
      };
      renderer.preferredType = "image";
      interfaces = {
        en0 = {
          network = "lan";
        };
      };
    };

    nixos-usb = {
      name = "🔌 USB Live System";
      deviceType = lib.mkForce "device";
      hardware = {
        info = "Portable USB NixOS";
        image = icon "nixos";
      };
      renderer.preferredType = "image";
      interfaces = {
        eth0 = {
          network = "lan";
        };
      };
    };

    # —— 便携/设备：不在 NixOS 配置里 ——
    nod-am = {
      name = "📱 Nix-on-Droid";
      deviceType = lib.mkForce "device";
      hardware = {
        info = "Android phone";
        image = icon "switch";
      };
      renderer.preferredType = "image";
      interfaces = {
        wlan0 = {
          network = "wan";
        };
      };
    };

    sm-vps = {
      name = "🧪 sm-vps Lab";
      deviceType = lib.mkForce "cloud-server";
      hardware = {
        info = "system-manager lab";
        image = icon "cloud";
      };
      renderer.preferredType = "image";
      interfaces = {
        eth0 = {
          network = "wan";
        };
      };
    };
  };
}
