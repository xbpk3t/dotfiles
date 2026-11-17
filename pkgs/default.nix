pkgs:
let
  sources = pkgs.callPackage ./sources.nix { };
in
{
  voltagent-subagents = sources.voltagent-subagents.src;
  dagu = pkgs.callPackage ./dagu { };
  opencli-extension = pkgs.callPackage ./opencli-extension { };
}
