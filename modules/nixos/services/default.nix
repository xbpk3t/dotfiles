{...}: let
  # Import the host-specific variables.nix
  vars = import ../../../hosts/nixos/default/variables.nix;
in {
  imports = [
    ./flatpak.nix
    ./greetd.nix
    ./nfs.nix
    ./printing.nix
    # Conditionally import the display manager module
    (
      if vars.displayManager == "tui"
      then ./greetd.nix
      else ./sddm.nix
    )
    ./syncthing.nix
    ./xserver.nix
  ];

  # Import any external service modules if needed
  # inputs.stylix.nixosModules.stylix
}
