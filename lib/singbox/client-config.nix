{
  config,
  pkgs,
  lib,
  mylib,
  ...
}:
with lib; let
  # singbox 节点清单直接从 inventory 读取，避免经过 vars/networking.nix
  servers = (import (mylib.relativeToRoot "inventory/nixos-vps.nix")).singboxServers;
  # NOTE:
  # - Darwin: we render a full JSON file via sops template (see modules/darwin/singbox-client.nix),
  #   so placeholders are required during evaluation and are substituted when the template is rendered.
  # - NixOS: services.sing-box consumes settings directly and expects secrets in {_secret = /path}
  #   so its preStart hook can replace them into /run/sing-box/config.json. Placeholders would
  #   not be substituted and would fail at evaluation time (missing attribute) or at runtime.
  # This split keeps Darwin working (no services.sing-box there) while making NixOS rebuild succeed.
  secrets =
    if pkgs.stdenv.isDarwin
    then {
      uuid = config.sops.placeholder.singbox_UUID;
      publicKey = config.sops.placeholder.singbox_pub_key;
      shortId = config.sops.placeholder.singbox_ID;
      flyingbirdPassword = config.sops.placeholder.singbox_flyingbird;
    }
    else {
      uuid = {_secret = config.sops.secrets.singbox_UUID.path;};
      publicKey = {_secret = config.sops.secrets.singbox_pub_key.path;};
      shortId = {_secret = config.sops.secrets.singbox_ID.path;};
      flyingbirdPassword = {_secret = config.sops.secrets.singbox_flyingbird.path;};
    };

  ruleSets = import ./ruleset.nix {
    enableRuleSetExtras = true;
  };
  outbounds = import ./outbounds.nix {
    inherit servers;
    uuid = secrets.uuid;
    publicKey = secrets.publicKey;
    shortId = secrets.shortId;
    flyingbirdPassword = secrets.flyingbirdPassword;
  };
  # config.nix only accepts outbounds + ruleSets; keep args aligned to avoid eval errors
  configJson = import ./config.nix {
    inherit outbounds ruleSets;
  };
  clientConfigPath = config.sops.templates."singbox-client.json".path;
  templatesContent = builtins.toJSON configJson;
in {
  inherit configJson clientConfigPath templatesContent;
}
