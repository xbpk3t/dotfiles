{...}: let
  mkPrefixedPaths = prefix: modules: map (path: "${prefix}/" + path) modules;
  mkTags = names:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = true;
      })
      names
    );
in {
  nixosConfigurations.nixos-vps = {
    system = "x86_64-linux";
    modules =
      mkPrefixedPaths "modules" [
        "base"
        "nixos/base"
        "nixos/vps"
        "nixos/extra"
        "nixos/cntr"
      ]
      ++ mkPrefixedPaths "home" [
        # Servers only need headless core modules plus the minimal NixOS set
        "base/core"
        "nixos/base"
      ];
  };

  nixosConfigurations.nixos-ws = {
    system = "x86_64-linux";
    modules =
      mkPrefixedPaths "modules" [
        "base"
        "nixos/base"
        "nixos/desktop"
      ]
      ++ mkPrefixedPaths "home" [
        "base"
        "nixos"
      ];
    tags = mkTags [
      "workstation"
      "graphics"
      "wayland"
    ];
  };
}
