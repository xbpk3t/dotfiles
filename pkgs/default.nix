pkgs:
let
  sources = pkgs.callPackage ./sources.nix { };
in
{
  voltagent-subagents = sources.voltagent-subagents.src;
  herdr-focus-notify = pkgs.callPackage ./herdr-focus-notify {
    inherit sources;
  };
  herdr-reviewr = pkgs.callPackage ./herdr-reviewr {
    inherit sources;
  };
}
