{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, etc.
  inputs,
  mylib,
  ...
}: let
  name = "nixos-ws";

  # Load host variables to determine profile  # Fallback to vm if not specified

  modules = {
    nixos-modules =
      (map mylib.relativeToRoot [
        # Host-specific configuration
        "hosts/${name}/default.nix"
        # common
        "secrets/default.nix"
        "modules/base"
        "modules/nixos/base"
        "modules/nixos/desktop"
      ])
      ++ [
        inputs.sops-nix.nixosModules.sops
        {
          modules.desktop.wayland.enable = true;
        }
      ];
    home-modules = map mylib.relativeToRoot [
      # Host-specific home configuration
      "hosts/${name}/home.nix"
      "home/base"
      "home/nixos"
    ];
  };
in {
  nixosConfigurations.${name} = mylib.nixosSystem (modules // args);
}
