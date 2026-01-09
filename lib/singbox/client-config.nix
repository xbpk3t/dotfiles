{
  config,
  pkgs,
  myvars,
  lib,
  ...
}:
with lib; let
  servers = myvars.networking.singboxServers;
  secrets = {
    uuid = config.sops.placeholder.singbox_UUID;
    publicKey = config.sops.placeholder.singbox_pub_key;
    shortId = config.sops.placeholder.singbox_ID;
    flyingbirdPassword = config.sops.placeholder.singbox_flyingbird;
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
  configJson = import ./config.nix {
    inherit outbounds ruleSets pkgs;
  };
  clientConfigPath = config.sops.templates."singbox-client.json".path;
  templatesContent = builtins.toJSON configJson;
in {
  inherit configJson clientConfigPath templatesContent;
}
