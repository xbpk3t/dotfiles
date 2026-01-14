{
  inputs,
  lib,
  mylib,
  myvars,
  ...
} @ args: let
  name = "nixos-homelab";
  tags = [
    name
    "homelab"
  ];

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
    ];
  };
  role = mylib.mkColmenaRole {
    inherit
      lib
      mylib
      genSpecialArgs
      modules
      args
      name
      ;
    system = "x86_64-linux";
    baseTags = tags;
    targets = [
      {
        host = "100.81.204.63";
        # user = ssh-user;
        user = "root";
        tags = tags;
        port = null;
      }
    ];
  };
in {
  inherit (role) nixosConfigurations colmena;
}
