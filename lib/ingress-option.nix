{lib}: serviceLabel: let
  inherit (lib) mkEnableOption mkOption types;
in
  types.submodule {
    options = {
      enable = mkEnableOption "Expose ${serviceLabel} through the shared reverse proxy";
      domain = mkOption {
        type = types.str;
        description = "Fully qualified domain name (usually proxied by Cloudflare) for ${serviceLabel}.";
      };
      target = mkOption {
        type = types.str;
        description = "Backend URL (e.g. http://127.0.0.1:8080) that ${serviceLabel} listens on.";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra per-site Caddy directives (rate limiting, headers, etc.).";
      };
      disableTls = mkOption {
        type = types.bool;
        default = true;
        description = "Serve this host over plain HTTP instead of HTTPS (useful when TLS terminates at Cloudflare).";
      };
    };
  }
