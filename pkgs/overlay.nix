final: prev:
let
  customPkgs = import ./default.nix prev;
in
customPkgs
