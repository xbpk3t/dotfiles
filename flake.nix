rec {
  description = "NixOS for Me";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    # 主仓库默认收敛到 rolling branch。
    # Why:
    # - 大多数桌面/开发 host 继续跟随 nixpkgs-unstable，降低 branch maintenance 成本
    # - 公网 VPS 通过 host metadata 单独切到 stable package set，减少滚动更新风险
    # - channel 选择只在 host 边界发生，不引入全局双通道抽象层
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs：声明与真实解析对齐。Nix 在本 flake 图里对顶层 nixpkgs 实际解析为 nixos-unstable
    # （lock 的 original.ref 即如此），保持声明一致避免 flake.nix 与 flake.lock 的 ref 漂移。
    # 注意：`nix flake lock --update-input nixpkgs` 对顶层 nixpkgs 结构性失效（本仓预存问题），
    # 需要刷新时手动 `nix flake lock --recreate-lock-file`。
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    # home-manager, used for managing user configuration
    home-manager = {
      # 默认随 rolling 演进；stable host 通过 useGlobalPkgs 复用对应系统 pkgs。
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      # nix-darwin 也统一跟随 rolling branch，避免 Darwin 侧单独维护 release pin。
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Keep nix-homebrew for compatibility
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";

    # Global agent skill sources (ASN).
    # flake = false: these repos are skill sources, not flakes.
    opencli-skills = {
      url = "github:jackwener/opencli";
      flake = false;
    };
    reclaim-code-entropy-skills = {
      url = "github:Yevanchen/reclaim-code-entropy";
      flake = false;
    };
    # gstack-skills 暂时注释：plan-ceo-review 缺 gstack bin/，见 home/base/AI/skills.nix。
    # gstack-skills = {
    #   url = "github:garrytan/gstack";
    #   flake = false;
    # };
    cloudflare-security-audit-skills = {
      url = "github:cloudflare/security-audit-skill";
      flake = false;
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # nixos-cli - Modern NixOS management CLI
    nixos-cli = {
      url = "github:water-sucks/nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter = {
      url = "github:nix-community/nixos-facter";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-topology: 从 flake 的 nixosConfigurations 自动生成舰队拓扑 SVG
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    "deploy-rs" = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS as a WSL2 distribution（Windows Server 2022 PA: 0cadhjae-vmez89）。
    # 上游 release 仍是 26.05 线；模块跟 main，switch 时随仓库 nixpkgs 走。
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix unit testing tools
    nix-unit.url = "github:nix-community/nix-unit";

    # system-manager: 非 NixOS Linux 的系统级声明管理（sm-vps 平行轨）
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # nix-unit 的 flake-parts module：提供 perSystem.nix-unit.{inputs,tests}，
        # 并自动生成 checks.<system>.nix-unit（随 `nix flake check` 一起跑）。
        # Why: 用它把 host 元数据一致性断言挂进默认质量闸门，与现有写好的 mkEvalCheck 互补。
        inputs.nix-unit.modules.flake.default
        (
          { lib, ... }:
          {
            options.globals = lib.mkOption {
              description = "Cross-host shared configuration that is not host identity metadata.";
              type = lib.types.attrs;
            };

            config.globals = {
              # Gateway 模型 id：claude/codex/worktrunk 共用，升级只改这里。
              # 存裸 id；claude 的 alias 再拼 CC 侧 1M context 标记 [1m]。
              models = {
                dsf = "deepseek-v4.1-flash";
                gpt = "gpt-6-astra";
              };

              # 全局身份常量：所有 host 共享。
              # Why: user/time/editor 不是 fleet topology，不该每个节点在
              # fleet registry 里复制一份；per-host 差异由 host 模块覆盖。
              identity = {
                user = {
                  username = "luck";
                  mail = "yyzw@live.com";
                };
                time = {
                  timeZone = "Asia/Shanghai";
                };
                editor = {
                  command = "hx";
                  desktopEntry = "Helix.desktop";
                  lazygitPreset = "helix";
                };
              };

              networking.nameservers = [
                "119.29.29.29"
                "223.5.5.5"
                "2400:3200::1"
                "2606:4700:4700::1111"
              ];

              # Global system preferences shared across hosts.
              # 用户密码 hash 走 sops（ME_PASS_HASH），见 secrets/default.nix。
              auth = {
                # Human/ops keys trusted across the fleet.
                adminKeys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDth3yFJZ2p5tID2W2AHI3s6t6B8oU3nSVBIJANNxyIG nixos-cntr"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7x+rABbX8F5M7o3JhuzC3nifn3/ePgLXp5WaW/8FiE nixos-vps"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbnHbU+syywmhd+ywtJwsc8+IKuuph5Ol+TmxC8pZHH luck@macos-ws"
                ];

                # Dedicated deploy keys, trusted on VPS hosts only. Keeping
                # these separate from adminKeys lets a compromised node's
                # deploy key be rotated without touching human access.
                deployKeys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzVmb4UevRyQgVJ649u1fc7yghYic3gdK7BF4dryEmn nixos-vps-agt-deploy"
                ];
              };
            };
          }
        )
        ./outputs
      ]
      ++ [
        # flake-parts module: 提供 perSystem `topology` 配置，用于 README 舰队拓扑图。
        inputs.nix-topology.flakeModule
      ];
    };
}
