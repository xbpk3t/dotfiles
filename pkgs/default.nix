pkgs: let
  sources = pkgs.callPackage ./sources.nix {};
in {
  apple-pingfang = pkgs.callPackage ./apple-pingfang {};
  zashboard = pkgs.callPackage ./zashboard {
    inherit sources;
  };
}
