{...}: let
  mkPrefixedPaths = prefix: modules: map (path: "${prefix}/" + path) modules;
  mkTags = attrs: attrs // {server = true;};
in {
  nixosConfigurations.nixos-vps = {
    system = "x86_64-linux";
    modules =
      mkPrefixedPaths "modules" [
        "base"
        "nixos/base"
        "nixos/vps"
      ]
      ++ mkPrefixedPaths "home" [
        # Servers only need headless core modules plus the minimal NixOS set
        "base/core"
        "nixos/base"
      ];
    tags = mkTags {
      region = "AP-south";
    };
  };
}
