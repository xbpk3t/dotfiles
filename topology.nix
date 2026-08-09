{
  inputs,
  lib,
  ...
}:
{
  topology = {
    # 全局拓扑定义：只声明网络与外部设备；
    # 主机信息从 nixosConfigurations 自动提取（见 flake.nix 的 topology.modules）。
    networks = {
      tailnet = {
        name = "Tailnet";
        # CIDR 带入 tailscale IP 网段（100.x）
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
      nixos-ws = {
        interfaces = {
          eth0 = { network = "lan"; };
        };
      };
      macos-ws = {
        interfaces = {
          en0 = { network = "lan"; };
        };
      };
      nixos-homelab = {
        interfaces = {
          eth0 = { network = "tailnet"; };
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
      nixos-usb = {
        interfaces = {
          eth0 = { network = "lan"; };
        };
      };
      nixos-avf = {
        interfaces = {
          enp0 = { network = "lan"; };
        };
      };
      nod-am = {
        interfaces = {
          wlan0 = { network = "wan"; };
        };
      };
      sm-vps = {
        interfaces = {
          eth0 = { network = "wan"; };
        };
      };
    };
  };
}
