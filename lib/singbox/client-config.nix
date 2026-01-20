{
  config,
  pkgs,
  lib,
  mylib,
  ...
}:
with lib; let
  # singbox 节点清单直接从 inventory/nodes 读取，避免重复手写
  inventory = import (mylib.relativeToRoot "inventory/nixos-vps.nix");
  nodes = inventory.nodes or {};
  servers = lib.lists.filter (s: s != null) (
    lib.attrsets.mapAttrsToList (
      name: node:
        if node ? singbox
        then
          node.singbox
          // {
            hostName = node.hostName or name;
            server = node.singbox.server or node.targetHost;
          }
        else null
    )
    nodes
  );
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
      clashSecret = config.sops.placeholder.singbox_clash_secret;
      flyingbirdPassword = config.sops.placeholder.singbox_flyingbird;
      hy2Password = config.sops.placeholder.singbox_hy2_pwd;
    }
    else {
      uuid = {
        _secret = config.sops.secrets.singbox_UUID.path;
      };
      publicKey = {
        _secret = config.sops.secrets.singbox_pub_key.path;
      };
      shortId = {
        _secret = config.sops.secrets.singbox_ID.path;
      };
      clashSecret = {
        _secret = config.sops.secrets.singbox_clash_secret.path;
      };
      flyingbirdPassword = {
        _secret = config.sops.secrets.singbox_flyingbird.path;
      };
      hy2Password = {
        _secret = config.sops.secrets.singbox_hy2_pwd.path;
      };
    };

  ruleSets = import ./ruleset.nix {
    enableRuleSetExtras = true;
  };
  outbounds = import ./outbounds.nix {
    inherit servers;
    inherit lib;
    uuid = secrets.uuid;
    publicKey = secrets.publicKey;
    shortId = secrets.shortId;
    flyingbirdPassword = secrets.flyingbirdPassword;
    hy2Password = secrets.hy2Password;
  };
  # config.nix requires pkgs for external_ui plus outbounds/ruleSets
  configJson = import ./config.nix {
    inherit outbounds ruleSets pkgs;
    clashSecret = secrets.clashSecret;
  };
  clientConfigPath = config.sops.templates."singbox-client.json".path;
  templatesContent = builtins.toJSON configJson;
in {
  inherit configJson clientConfigPath templatesContent;
}
