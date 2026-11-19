# fleet registry 由 outputs/default.nix 注入（flake 层已求值一次），
# 避免这里再 import ./lib/fleet 扫描一遍 hosts/**/meta.nix。
{ fleet }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.topology) mkInternet mkRouter mkConnection;

  # 手工维护的拓扑事实。节点名必须来自 fleet；新增非 NixOS 节点时
  # 必须在这里补定义，否则下面的 assert 会直接失败，而不是静默画错。
  # NixOS 节点仍由 nix-topology 从 nixosConfigurations 自动提取，这里只补
  # 自动提取不到的接口/硬件事实。
  manualNodes = {
    # —— 自动提取的 NixOS 主机：补接口定义（host 用 NetworkManager/DHCP，无静态接口）——
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
    # agt 的 DHCP 接口没有被 nix-topology 提取；ens5 依据
    # modules/nixos/infra/tailscale-client.nix 里 mihomo policy-route 的注释。
    nixos-vps-agt = {
      interfaces = {
        ens5 = {
          network = "wan";
        };
      };
    };

    # —— 家庭设备（host 名作节点名；注释里写明角色说明）——
    # macos-ws：macOS 工作站（MacBook M4 Pro）
    macos-ws = {
      deviceType = lib.mkForce "laptop";
      deviceIcon = "os.apple";
      hardware.info = "MacBook M4 Pro";
      interfaces = {
        en0 = {
          network = "lan";
        };
      };
    };

    # —— 便携/设备：不在 NixOS 配置里 ——
    # sm-vps-hk：共享 VPS（system-manager 平行轨）
    sm-vps-hk = {
      deviceType = "cloud-server";
      deviceIcon = "os.debian";
      hardware.info = "Shared VPS (Tencent HK)";
      interfaces = {
        eth0 = {
          network = "wan";
        };
      };
    };

    # sm-vps-tc：dedicated VPS（system-manager 平行轨）
    sm-vps-tc = {
      deviceType = "cloud-server";
      deviceIcon = "os.debian";
      hardware.info = "Dedicated VPS (Tencent)";
      interfaces = {
        eth0 = {
          network = "wan";
        };
      };
    };
  };

  # 拓扑图内部使用、但不是 fleet host 的虚拟节点。
  # 单独成集后，manualNodes 的覆盖断言不再需要按名字白名单排除它们。
  virtualNodes = {
    # —— 互联网节点：连接所有公网出口 ——
    internet = mkInternet {
      connections = [
        (mkConnection "nixos-vps-agt" "ens5")
        (mkConnection "nixos-vps-dev" "ens3")
        (mkConnection "sm-vps-hk" "eth0")
        (mkConnection "sm-vps-tc" "eth0")
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
          (mkConnection "nixos-usb" "eth0")
          (mkConnection "macos-ws" "en0")
        ];
        wan1 = mkConnection "internet" "*";
      };
    };
  };

  # 非 NixOS 节点不会被 nix-topology 从 nixosConfigurations 自动提取。
  nonNixosNodeNames = lib.attrNames (lib.filterAttrs (_: node: node.kind != "nixos") fleet.nodes);

  missingNonNixos = lib.filter (name: !(manualNodes ? ${name})) nonNixosNodeNames;
  unknownManual = lib.filter (name: !(fleet.nodes ? ${name})) (lib.attrNames manualNodes);
in
assert lib.assertMsg (missingNonNixos == [ ])
  "topology: non-NixOS fleet nodes lack topology definitions: ${lib.concatStringsSep ", " missingNonNixos}";
assert lib.assertMsg (unknownManual == [ ])
  "topology: topology defines nodes that are not in the fleet: ${lib.concatStringsSep ", " unknownManual}";
{
  # 自定义 OS 图标，供 node 的 icon/deviceIcon 用 <category>.<name> 引用。
  # nix-topology 的 icons 选项类型是 attrsOf (attrsOf { file = path; })。
  # debian：从 devicon（钉死 commit）拉取，彩色品牌 logo。
  # - devicon 是 GitHub raw，可钉死 commit，纯 <path> 结构，nix-topology 的
  #   builtins.readFile 内联渲染完全兼容。
  # apple：devicon 的 apple-original 是纯黑单 path，在深色卡片上看不清；
  #   改用 iconify API 直接返回白色版本（simple-icons 数据源 + ?color 参数），
  #   零后处理即可见。响应内容用 hash 锁定。
  #   注意：iconify 的路径语法是 "set/icon"；旧的 "set:icon" 现在会 404。
  # 为什么不用 svgrepo：/download/ 端点对数据中心 IP 返回 429 反爬（实测），
  #   /show/ 不稳定，在 VPS 上 fetchurl 会抓到反爬 HTML 而不是 SVG。
  icons.os = {
    debian.file = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/devicons/devicon/7330accdbc47e2dc0c19789a48533c4a3c50fe58/icons/debian/debian-original.svg";
      hash = "sha256-CbFMmBOjIrWLEapTkPsaK06b/QKGgyFILxoZU0pm7FQ=";
      name = "debian.svg";
    };
    apple.file = pkgs.fetchurl {
      url = "https://api.iconify.design/simple-icons/apple.svg?color=%23e3e6eb";
      hash = "sha256-xysN4lI3oHPTplAq5UM7lYf8800owTUHIaTGbDL71NI=";
      name = "apple.svg";
    };
  };

  # 全局拓扑定义：声明网络与外部设备；
  # 主机节点信息由 nix-topology 从 nixosConfigurations 自动提取
  # （见 outputs/default.nix 的 topology.modules 注入）。
  #
  # 参考 TheMaxMur/NixOS-Configuration 的写法：
  #   mkInternet / mkRouter / mkConnection
  # 让 README 的拓扑图能看出真实链路（Internet → VPS/家庭路由 → 各设备）。
  networks = {
    lan = {
      name = "Home LAN";
      cidrv4 = "192.168.0.0/16";
    };
    wan = {
      name = "WAN (Internet)";
    };
  };

  # 非 NixOS 节点不会从 nixosConfigurations 自动提取；manualNodes 必须覆盖
  # 所有非 NixOS fleet 节点（上面的 assert 强制），NixOS 节点继续自动提取。
  nodes = manualNodes // virtualNodes;
}
