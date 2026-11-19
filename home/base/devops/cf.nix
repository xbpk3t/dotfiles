{ config, lib, ... }:
let
  cfg = config.modules.devops.cf;
in
{
  options.modules.devops.cf.enable =
    lib.mkEnableOption "Cloudflare env vars (CF_ACCOUNT / CF_ZONE / R2 / API token)";

  config.home.sessionVariables = lib.mkIf cfg.enable {
    # 保留短名字，方便手工排查或临时脚本使用。
    CF_ACCOUNT = "$(cat ${config.sops.secrets.CF_ACCOUNT.path})";
    CF_ZONE = "$(cat ${config.sops.secrets.CF_ZONE.path})";
    CF_R2_AK = "$(cat ${config.sops.secrets.CF_R2_AK.path})";
    CF_R2_SK = "$(cat ${config.sops.secrets.CF_R2_SK.path})";

    # docs-cli / wiki digest 使用的标准名字。
    R2_AK = "$(cat ${config.sops.secrets.CF_R2_AK.path})";
    R2_SK = "$(cat ${config.sops.secrets.CF_R2_SK.path})";
    R2_ENDPOINT = "https://$(cat ${config.sops.secrets.CF_ACCOUNT.path}).r2.cloudflarestorage.com";

    CLOUDFLARE_API_TOKEN = "$(cat ${config.sops.secrets.CLOUDFLARE_API_TOKEN.path})";
  };
}
