{
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  nixosSystemArgs = args // {inherit lib;};
  name = "nixos-homelab";

  # 与 nixos-ws 共用 overlay；禁用 NVIDIA 但保留 unfree 支持
  genSpecialArgs = system: let
    customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [customPkgsOverlay];
    };
  in {
    inherit inputs mylib myvars pkgs;
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
      [inputs.sops-nix.nixosModules.sops]
      ++ map mylib.relativeToRoot [
        "hosts/${name}/default.nix"
        "secrets/default.nix"
        "modules/nixos/base"
        "modules/nixos/hardware/nvidia.nix"
        "modules/nixos/extra/singbox-client.nix"
        "modules/nixos/extra/vscode-remote.nix"

        # homelab 需要时可启用 k3s 模块，先在 host 层决定
        # "modules/nixos/homelab/k3s.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${name}/home.nix"
      "home/base/core"
      "home/base/tui"
      "home/nixos"
    ];
  };
in {
  nixosConfigurations.${name} = mylib.nixosSystem (nixosSystemArgs
    // modules
    // {
      genSpecialArgs = genSpecialArgs;
    });

  colmenaProfiles.${name} = {
    inherit (modules) system nixos-modules home-modules;
    genSpecialArgs = genSpecialArgs;
    defaultTargetUser = myvars.username or "root";
  };
}
