{
  config,
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
  extraOutbounds = import ./extra-outbounds.nix {
    flyingbirdPassword = secrets.flyingbirdPassword;
  };
  configJson = import ./config.nix {
    inherit servers extraOutbounds;
    uuid = secrets.uuid;
    publicKey = secrets.publicKey;
    shortId = secrets.shortId;
  };
  clientConfigPath = config.sops.templates."singbox-client.json".path;
  templatesContent = builtins.toJSON configJson;
in {
  inherit configJson clientConfigPath templatesContent;
}
