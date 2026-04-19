pkgs: let
  sources = pkgs.callPackage ./sources.nix {};
in {
  apple-pingfang = pkgs.callPackage ./apple-pingfang {};
  chrome-devtools-mcp = pkgs.callPackage ./chrome-devtools-mcp {
    inherit sources;
  };
  zashboard = pkgs.callPackage ./zashboard {
    inherit sources;
  };
}
