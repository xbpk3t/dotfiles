{
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  name = "nixos-homelab";
  ssh-user = "root";
  inventory = mylib.inventory."nixos-homelab";
  nodes = inventory;

  # 与 nixos-ws 共用 overlay；禁用 NVIDIA 但保留 unfree 支持
  genSpecialArgs = system: let
    customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  in {
    inherit
      inputs
      mylib
      myvars
      pkgs
      ;
    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  };

  modules = {
    system = "x86_64-linux";
    inherit lib myvars;
    nixos-modules =
      [
        inputs.sops-nix.nixosModules.sops
      ]
      ++ map mylib.relativeToRoot [
        "hosts/${name}/default.nix"
        "secrets/default.nix"
        "modules/nixos/base"
        "modules/nixos/homelab"

        "modules/nixos/hardware/nvidia.nix"
        "modules/nixos/extra/singbox-client.nix"
        "modules/nixos/extra/vscode-remote.nix"
        "modules/nixos/extra/fhs.nix"
        "modules/nixos/extra/k3s.nix"

        # homelab 需要时可启用 k3s 模块，先在 host 层决定
        # "modules/nixos/homelab/k3s.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${name}/home.nix"
      "home/base/core"
      "home/base/tui"
      "home/nixos"
      "home/extra/jetbrains-remote.nix"
      "home/extra/zed-remote.nix"
    ];
  };

  mkNodeModule = name: node:
    {
      # What：hostName 由 inventory 注入。
      # Why：避免单机调试时为空，同时统一节点元数据入口。
      networking.hostName = node.hostName or name;
    }
    // lib.optionalAttrs (node ? k3s) {
      modules.extra.k3s = node.k3s;
    };

  mkNodeRole = name: node: let
    nodeModule = mkNodeModule name node;
    modulesWithNode =
      modules
      // {
        nixos-modules = modules.nixos-modules ++ [nodeModule];
      };
    systemArgs = modulesWithNode // args;
    nixosConfig = mylib.nixosSystem (
      systemArgs
      // {
        inherit genSpecialArgs;
      }
    );
    deployNode = mylib.inventory.deployRsNode {
      inherit name node;
      nixosConfiguration = nixosConfig;
      deployLib = inputs."deploy-rs".lib."x86_64-linux";
      defaultSshUser = ssh-user;

      # [2026-01-25] 目前 dotfiles 在 mac 本地，所以 homelab 应开启 remoteBuild
      remoteBuild = true;
    };
  in {
    nixosConfigurations.${name} = nixosConfig;
    deploy.nodes.${name} = deployNode;
  };

  nodeRoles = builtins.attrValues (builtins.mapAttrs mkNodeRole nodes);

  merged = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or {}) nodeRoles
    );
    deploy = {
      nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) nodeRoles);
    };
  };
in {
  nixosConfigurations = merged.nixosConfigurations;
  deploy = merged.deploy;
}
