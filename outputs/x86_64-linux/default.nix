{mylib, ...} @ args: let
  name = "nixos-ws";

  modules = {
    nixos-modules =
      (map mylib.relativeToRoot [
        # Host configuration
        "hosts/${name}/default.nix"
        # Base modules
        "modules/nixos/base"
        # Desktop modules
        "modules/nixos/desktop.nix"
      ])
      ++ [
        # Boot configuration
        ({...}: {
          # Use systemd-boot instead of GRUB for UEFI systems
          boot.loader = {
            efi.canTouchEfiVariables = true;
            efi.efiSysMountPoint = "/boot";
            systemd-boot.enable = true;
            timeout = 10;
          };
          # Allow unfree packages for nvidia drivers
          nixpkgs.config.allowUnfree = true;
        })
        # Enable Wayland
        ({...}: {
          modules.desktop.wayland.enable = true;
        })
      ];
    home-modules = map mylib.relativeToRoot [
      # Home manager configuration
      "home/nixos/default.nix"
      # Host-specific home configuration
      "hosts/${name}/home.nix"
    ];
  };
in {
  # NixOS Configurations
  nixosConfigurations.${name} = mylib.nixosSystem (modules // args);

  # Tests
  evalTests = {};
}
