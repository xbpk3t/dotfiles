pkgs:
let
  sources = pkgs.callPackage ./sources.nix { };
in
{
  apple-pingfang = pkgs.callPackage ./apple-pingfang { };
  voltagent-subagents = sources.voltagent-subagents.src;
  cc-connect = pkgs.callPackage ./cc-connect { };

  chrome-devtools-mcp = pkgs.callPackage ./chrome-devtools-mcp {
    inherit sources;
  };
  launchk = pkgs.callPackage ./launchk {
    inherit sources;
  };
  trzsz-go = pkgs.callPackage ./trzsz-go {
    inherit sources;
  };
}
