pkgs:
let
  sources = pkgs.callPackage ./sources.nix { };
in
{
  voltagent-subagents = sources.voltagent-subagents.src;
  dagu = pkgs.callPackage ./dagu { };
  opencli-extension = pkgs.callPackage ./opencli-extension { };
  apm-bin = pkgs.callPackage ./apm-bin {
    inherit (sources)
      apm-bin-x86_64-linux
      apm-bin-aarch64-linux
      apm-bin-aarch64-darwin
      apm-bin-x86_64-darwin
      ;
  };
}
