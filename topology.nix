{
  inputs,
  lib,
  ...
}:
let
  icon = name: ./assets/topology-icons/${name}.svg;
in
{
  # 全局拓扑定义：声明网络与外部设备；
  # 主机节点信息由 nix-topology 从 nixosConfigurations 自动提取
  # （见 outputs/default.nix 的 topology.modules 注入）。
  #
  # C 版（全图标模式）：所有节点渲染为紧凑图标 + 名称，
  # 图面干净，适合 README 展示舰队全貌。
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
    # —— 主机：全部用紧凑图标 ——
    nixos-ws = {
      name = "🖥️ NixOS Workstation";
      deviceType = lib.mkForce "desktop";
      hardware = {
        info = "AMD Ryzen desktop, Nvidia GPU";
        image = icon "desktop";
      };
      renderer.preferredType = "image";
      interfaces = {
        eth0 = { network = "lan"; };
      };
    };
    nixos-homelab = {
      name = "🏠 Homelab";
      deviceType = lib.mkForce "nixos";
      hardware = {
        info = "NixOS server, k3s node";
        image = icon "nixos";
      };
      renderer.preferredType = "image";
      interfaces = {
        eth0 = { network = "tailnet"; };
        tailscale0 = { network = "tailnet"; };
      };
    };
    nixos-vps-dev = {
      name = "☁️ VPS Dev";
      deviceType = lib.mkForce "cloud-server";
      hardware = {
        info = "Public VPS, incus + k3s";
        image = icon "cloud-server";
      };
      renderer.preferredType = "image";
      interfaces = {
        ens3 = { network = "wan"; };
        tailscale0 = { network = "tailnet"; };
      };
    };
    nixos-vps-svc = {
      name = "☁️ VPS Service";
      deviceType = lib.mkForce "cloud-server";
      hardware = {
        info = "Public VPS, k3s service";
        image = icon "cloud-server";
      };
      renderer.preferredType = "image";
      interfaces = {
        ens3 = { network = "wan"; };
        tailscale0 = { network = "tailnet"; };
      };
    };
    # macOS 走 nix-darwin，不在 NixOS config 里，手动完整定义
    macos-ws = {
      name = "🍎 Mac Workstation";
      deviceType = lib.mkForce "laptop";
      hardware = {
        info = "Apple Silicon MacBook";
        image = icon "laptop";
      };
      renderer.preferredType = "image";
      interfaces = {
        en0 = { network = "lan"; };
      };
    };

    # —— 便携/设备：紧凑图标 ——
    nixos-usb = {
      name = "🔌 USB Live System";
      deviceType = lib.mkForce "device";
      hardware = {
        info = "Portable USB NixOS";
        image = icon "nixos";
      };
      renderer.preferredType = "image";
      interfaces = {
        eth0 = { network = "lan"; };
      };
    };
    nod-am = {
      name = "📱 Nix-on-Droid";
      deviceType = lib.mkForce "device";
      hardware = {
        info = "Android phone";
        image = icon "switch";
      };
      renderer.preferredType = "image";
      interfaces = {
        wlan0 = { network = "wan"; };
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
        eth0 = { network = "wan"; };
      };
    };
  };
}