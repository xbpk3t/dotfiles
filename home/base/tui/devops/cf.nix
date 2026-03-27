{config, ...}: {
  home.sessionVariables = {
    # 保留短名字，方便手工排查或临时脚本使用。
    CF_ACCOUNT = "$(cat ${config.sops.secrets.cf_account.path})";
    CF_ZONE = "$(cat ${config.sops.secrets.cf_zone.path})";
    CF_R2_AK = "$(cat ${config.sops.secrets.cf_r2_AK.path})";
    CF_R2_SK = "$(cat ${config.sops.secrets.cf_r2_SK.path})";

    # 看看能否不用这个 CLOUDFLARE_API_TOKEN 的 key? 感觉会很不清晰，容易混淆
    CLOUDFLARE_API_TOKEN = "$(cat ${config.sops.secrets.cf_token_read_all.path})";

    # 我在 cloudflare-pages-auth 里设置的pwd
    TF_VAR_pages_docs_cfp_pwd = "$(cat ${config.sops.secrets.cf_workers_cfp.path})";
  };
}
