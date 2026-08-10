{
  config,
  lib,
  ...
}:
let
  inherit (config.lib.topology) mkInternet mkRouter mkConnection;
in
{
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
        eth0 = {
          network = "lan";
        };
      };
    };
    nixos-homelab = {
      interfaces = {
        eth0 = {
          network = "lan";
        };
      };
    };
    # nixos-usb：自动提取（deviceType=nixos → snowflake 图标 + card），
    # 只补 hardware.info 和 eth0 接口；NetworkManager 模式提取不到接口
    nixos-usb = {
      hardware.info = "Portable USB NixOS";
      interfaces = {
        eth0 = {
          network = "lan";
        };
      };
    };
    nixos-vps-dev = {
      interfaces = {
        ens3 = {
          network = "wan";
        };
      };
    };
    nixos-vps-svc = {
      interfaces = {
        ens3 = {
          network = "wan";
        };
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

      interfaceGroups = [
        [ "wan1" ]
        [ "eth1" ]
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
          (mkConnection "nixos-homelab" "eth0")
          (mkConnection "nixos-usb" "eth0")
          (mkConnection "macos-ws" "en0")
          (mkConnection "nod-am" "wlan0")
          (mkConnection "nixos-avf" "eth0")
        ];
        wan1 = mkConnection "internet" "*";
      };
    };

    # —— 家庭设备（host 名作节点名；注释里写明角色说明）——
    # macos-ws：macOS 工作站（MacBook M4 Pro）
    macos-ws = {
      deviceType = lib.mkForce "laptop";
      hardware.info = "MacBook M4 Pro";
      interfaces = {
        en0 = {
          network = "lan";
        };
      };
    };

    # nixos-avf：Android AVF 虚拟机里的 NixOS（开发机 remote server），
    # 自动提取（deviceType=nixos → card + Fail2Ban 服务），
    # 只补 hardware.info 和 eth0 接口；网络由 AVF 虚拟化提供（virtio-net，走宿主手机网络）
    nixos-avf = {
      hardware.info = "NixOS on Android AVF";
      interfaces = {
        eth0 = {
          network = "lan";
        };
      };
    };

    # —— 便携/设备：不在 NixOS 配置里 ——
    # nod-am：Android 手机（Nix-on-Droid）
    nod-am = {
      deviceType = lib.mkForce "device";
      hardware.info = "Nix-on-Droid (Android)";
      interfaces = {
        wlan0 = {
          network = "lan";
        };
      };
    };

    # sm-vps：system-manager 实验 VPS
    sm-vps = {
      deviceType = lib.mkForce "cloud-server";
      hardware.info = "system-manager lab";
      interfaces = {
        eth0 = {
          network = "wan";
        };
      };
    };
  };
}
