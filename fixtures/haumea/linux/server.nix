{...}: let
  mkModules = modules: map (path: "modules/" + path) modules;
  mkTags = attrs: attrs // {server = true;};
in {
  nixosConfigurations.nixos-vps = {
    system = "x86_64-linux";
    modules = mkModules [
      "base"
      "nixos/base"
      "nixos/vps"
    ];
    tags = mkTags {
      region = "AP-south";
    };
  };
}
