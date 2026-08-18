{
  inputs,
  lib,
  mylib,
  mkSpecialArgs,
  ...
}@args:
let
  name = "nixos-vps";
  ssh-user = "root";

  # 角色（不变）：infra 基线
  baseModules = {
    system = "x86_64-linux";
    inherit lib;
    nixos-modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
    ]
    ++ map mylib.relativeToRoot [
      "hosts/${name}/default.nix"
      "secrets/default.nix"
      "modules/nixos/kernel"
      "modules/nixos/infra/nix-tools.nix"
      "modules/nixos/infra/mihomo-server.nix"
      "modules/nixos/infra/singbox-server.nix"
      "modules/nixos/infra/tailscale-client.nix"
      "modules/nixos/ms/k3s.nix"
    ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "secrets/default.nix"
      "home/core"
      # agent cockpit (pointwise — not whole home/base/devops)
      "home/base/devops/rclone.nix"
      "home/base/devops/herdr.nix"
      "home/base/devops/ghui.nix"
      "home/base/devops/hunk.nix"
      "home/base/devops/yazi.nix" # herdr ctrl+alt+y
      # helix.nix reads modules.langs.lsp.packages — import option def; leave lsp.enable false
      "home/base/langs/lsp.nix"
      "home/base/devops/helix.nix" # ghui/yazi/$EDITOR → hx; herdr popup open paths
      # k9s (+ kubectl toolchain). VPS already runs k3s; herdr ctrl+alt+k.
      "home/base/ms/k8s.nix"
      # Claude + shared skills (herdr ctrl+alt+a / resume_agents_on_restore hook)
      "home/base/AI/claude.nix"
      "home/base/AI/skills.nix"
    ];
  };

  # inventory（可变）：节点差异
  inventory = mylib.inventory."nixos-vps";
  nodes = inventory;

  mkNodeModule =
    name: node:
    let
      username = node.user.username or "luck";
      # Why not `// incusLab` with nested networking.*：
      # attrset `//` 是浅合并。右边若带 `networking.nftables` 会整表替换左边的
      # `networking`，把 hostName 冲掉 → 回落到 hosts 里 mkDefault "nixos-vps" →
      # singboxForHost 按错名查 inventory 报 attribute 'nixos-vps' missing。
      # mkMerge 由 module 系统做深合并，语义等价于逐项 mkIf 分挂，且无重复键。
      incusOn = node.incus.enable or false;
    in
    {
      # 变更项都放到 inventory，避免散落在各个 hosts
      networking = lib.mkMerge [
        { hostName = node.hostName or name; }
        (lib.mkIf incusOn {
          nftables.enable = true;
          firewall.trustedInterfaces = [ "incusbr0" ];
        })
      ];

      modules.networking.tailscale.derper = {
        enable = true;
        domain = node.tailscale.derpDomain;
        inherit (node) acmeEmail;
      };

      # Incus lab（I1+P-b）：最小 enable，无 preseed；init 在目标机手跑。
      virtualisation.incus.enable = lib.mkIf incusOn true;
      users.users.${username}.extraGroups = lib.mkIf incusOn [ "incus-admin" ];

      modules.ms.k3s = lib.mkIf (node ? k3s) node.k3s;
    };

  mkNodeRole =
    name: node:
    let
      nodeModule = mkNodeModule name node;
      modules = baseModules // {
        nixos-modules = baseModules.nixos-modules ++ [ nodeModule ];
      };
      systemArgs =
        modules
        // args
        // {
          specialArgs = mkSpecialArgs baseModules.system node;
        };
      nixosConfig = mylib.nixosSystem systemArgs;
      deployNode = mylib.inventory.deployRsNode {
        inherit name node;
        nixosConfiguration = nixosConfig;
        deployLib = inputs."deploy-rs".lib.${baseModules.system};
        defaultSshUser = ssh-user;
        remoteBuild = true;
      };
    in
    {
      nixosConfigurations.${name} = nixosConfig;
      deploy.nodes.${name} = deployNode;
    };

  nodeRoles = builtins.attrValues (builtins.mapAttrs mkNodeRole nodes);

  merged = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or { }) nodeRoles
    );
    deploy = {
      nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or { }) nodeRoles);
    };
  };
in
merged
