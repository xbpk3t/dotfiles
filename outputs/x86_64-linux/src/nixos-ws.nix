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
        # NixOS specific modules
        "modules/nixos/desktop.nix"
      ])
      ++ [
        inputs.sops-nix.nixosModules.sops
        {
          modules.desktop.wayland.enable = true;
        }
      ];
    home-modules = map mylib.relativeToRoot [
      # Home manager configuration
      "home/nixos/default.nix"
      # Host-specific home configuration
      "hosts/${name}/home.nix"
    ];
  };
in {
  nixosConfigurations.${name} = mylib.nixosSystem (modules // args);
}
