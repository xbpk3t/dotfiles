_final: prev: let
  customPkgs = import ./default.nix prev;
in
  customPkgs
  // {
    mihomo = prev.mihomo.overrideAttrs {
      tags = ["with_gvisor" "with_vless"];
    };
  }
