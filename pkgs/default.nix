pkgs: let
  sources = pkgs.callPackage ./sources.nix {};
in {
  apple-pingfang = pkgs.callPackage ./apple-pingfang {};
  chrome-devtools-mcp = pkgs.callPackage ./chrome-devtools-mcp {
    inherit sources;
  };
  launchk = pkgs.callPackage ./launchk {
    inherit sources;
  };
  trzsz-go = pkgs.callPackage ./trzsz-go {
    inherit sources;
  };
  zashboard = pkgs.callPackage ./zashboard {
    inherit sources;
  };
}
