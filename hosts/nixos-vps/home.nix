# Group HM base for all nixos-vps nodes.
#
# Node home.nix imports this and adds its role delta:
#   dev -> curated home/base cockpit
#   agt -> full home/base + home/nixos agent toolchain
{ mylib, ... }:
{
  imports = [
    (mylib.relativeToRoot "home/core")
    (mylib.relativeToRoot "secrets/default.nix")
  ];
}
