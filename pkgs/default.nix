pkgs:
let
  sources = pkgs.callPackage ./sources.nix { };
in
{
  voltagent-subagents = sources.voltagent-subagents.src;
  chrome-devtools-mcp = pkgs.callPackage ./chrome-devtools-mcp {
    inherit sources;
  };
  herdr-focus-notify = pkgs.callPackage ./herdr-focus-notify {
    inherit sources;
  };
  herdr-reviewr = pkgs.callPackage ./herdr-reviewr {
    inherit sources;
  };
  trzsz-go = pkgs.callPackage ./trzsz-go {
    inherit sources;
  };
}
