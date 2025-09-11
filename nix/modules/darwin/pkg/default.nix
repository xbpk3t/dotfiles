{...}: {
  imports = [
    ../../shared/packages.nix

    ./db.nix
    ./devops.nix
    ./kernel.nix
    ./langs.nix
    ./ms.nix
    ./works.nix
  ];
}
