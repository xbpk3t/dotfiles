{
  config,
  pkgs,
  lib,
  mylib,
  ...
}:
with lib; let
  # singbox 节点清单直接从 inventory 读取（lib/inventory/data.nix 分组结构）
  inventory = mylib.inventory."nixos-vps";
  nodes = inventory;
  servers = lib.lists.filter (s: s != null) (
    lib.attrsets.mapAttrsToList (
      name: node:
        if node ? singbox
        then
          node.singbox
          // {
            hostName = node.hostName or name;
            server = node.singbox.server or (mylib.inventory.primaryHostForNode name node);
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
      uuid = config.sops.placeholder.SINGBOX_UUID;
      publicKey = config.sops.placeholder.SINGBOX_PUB_KEY;
      shortId = config.sops.placeholder.SINGBOX_ID;
      clashSecret = config.sops.placeholder.SINGBOX_CLASH_SK;
      flyingbirdPassword = config.sops.placeholder.SINGBOX_FLYINGBIRD;
      hy2Password = config.sops.placeholder.SINGBOX_HY2_PWD;
    }
    else {
      uuid = {
        _secret = config.sops.secrets.SINGBOX_UUID.path;
      };
      publicKey = {
        _secret = config.sops.secrets.SINGBOX_PUB_KEY.path;
      };
      shortId = {
        _secret = config.sops.secrets.SINGBOX_ID.path;
      };
      clashSecret = {
        _secret = config.sops.secrets.SINGBOX_CLASH_SK.path;
      };
      flyingbirdPassword = {
        _secret = config.sops.secrets.SINGBOX_FLYINGBIRD.path;
      };
      hy2Password = {
        _secret = config.sops.secrets.SINGBOX_HY2_PWD.path;
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
