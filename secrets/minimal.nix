# Minimal sops secret set for disk/RAM-constrained VPS appliances.
#
# Nodes import exactly one of secrets/default.nix (full) or this file.
# A public-facing sing-box node only needs proxy material, the SSH password
# hash, ACME credentials and the Nezha agent secret; it must not hold the
# Cloudflare R2 / GitHub / LLM / restic credentials.
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
  # Key paths and ownership come from defs.nix; this list only selects the
  # subset the appliance decrypts.
  minimalKeys = [
    "ME_PASS_HASH"
    "PROXY_UUID"
    "PROXY_PRI_KEY"
    "PROXY_ID"
    "PROXY_PWD"
    "ACME_CF_ENV"
    "NEZHA_AGENT_SK"
  ];
in
{
  imports = [ ./common.nix ];

  # PROXY_PUB_KEY is client-side only and is not needed on the server.
  sops.secrets = lib.getAttrs minimalKeys defs.secrets;
}
