{
  fetchgit,
  fetchurl,
  fetchFromGitHub,
  dockerTools,
}:
import ./_sources/generated.nix {
  inherit
    fetchgit
    fetchurl
    fetchFromGitHub
    dockerTools
    ;
}
