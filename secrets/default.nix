# Full fleet secret set. Desktops and general-purpose VPS import this;
# disk/RAM-constrained appliances should import secrets/minimal.nix instead.
{
  config,
  lib,
  pkgs,
  userMeta,
  ...
}:
let
  defs = import ./defs.nix {
    inherit
      config
      lib
      pkgs
      userMeta
      ;
  };
in
{
  imports = [ ./common.nix ];

  sops.secrets = defs.secrets;
}
