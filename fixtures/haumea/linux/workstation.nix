{lib, ...}: let
  baseModules = [
    "modules/base"
    "modules/nixos/base"
  ];
  optionalModules = [
    "modules/nixos/desktop"
    "home/base"
    "home/nixos"
  ];
  mkTags = names:
    lib.listToAttrs (map (name: {
        inherit name;
        value = true;
      })
      names);
in {
  nixosConfigurations.nixos-ws = {
    system = "x86_64-linux";
    modules = baseModules ++ optionalModules;
    tags = mkTags [
      "workstation"
      "graphics"
      "wayland"
    ];
  };
}
