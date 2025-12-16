{ inputs, ... }: {
  imports = [
    ./args.nix
    ./pkgs.nix
    ./vars.nix
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
    ./devshell.nix
  ];

  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt;
  };
}
