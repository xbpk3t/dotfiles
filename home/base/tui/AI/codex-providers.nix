# [中转站]
# https://www.helpaio.com/transit
# https://cubence.com/
# https://relaypulse.top/ 感觉 SSSAiCode 还不错（小月卡）
# https://api.ikuncode.cc/console/topup gpt-5.4. 输入价格 ¥0.5/1M, 补全价格 ¥3/1M. 正好是 SSSAiCode 的一半
# [公益站]
# https://ldoh.105117.xyz/
# 公益站自动签到
# https://linux.do/t/topic/1001042/1117
# https://github.com/qixing-jk/all-api-hub
# [ChatGPT Plus]
# https://linux.do/t/topic/1837955/39 在mac用开 ChatGPT Plus (用土区+礼品卡，¥80/月)
{
  # Codex provider Metadata
  #
  # 必填：
  # - baseURL: Provider 的 OpenAI 兼容 API 地址。
  # - env: 注入 Codex 运行环境的环境变量名。
  # - sk: 对应 config.sops.secrets.<sk>.path 的 secret 名。
  #
  # 可选：
  # - wireApi: 映射到 model_providers.<name>.wire_api，默认 "responses"。
  # - model: 映射到 profiles.<name>.model，默认 "gpt-5.4"。
  #   这两个一般不用写，只有需要覆盖默认值时再写。
  #
  # 派生规则：
  # - attr 名（如 `ggboom`）会直接作为 provider/profile 名。
  # - shell alias 固定生成为 `codex-<name>`。

  # https://linux.do/t/topic/1806073
  # https://ice.v.ua/dashboard
  ice = {
    # https://linux.do/t/topic/1927587
    # base_url = "https://ice.v.ua/v1";
    baseURL = "https://icoe.pp.ua/v1";
    env = "OPENAI_API_KEY_ICE";
    sk = "LLM_Sub2API_default";
  };

  # https://linux.do/t/topic/1558896
  # https://ai.qaq.al/dashboard
  # https://sign.qaq.al/app
  ggboom = {
    baseURL = "https://ai.qaq.al/v1";
    env = "OPENAI_API_KEY_GGBoom";
    sk = "LLM_Sub2API_ggboom";
  };

  # https://linux.do/t/topic/1614522
  # https://openai.api-test.us.ci/console
  zzz = {
    # https://linux.do/t/topic/1912239/13
    # base_url = "https://new.api-test.us.ci/v1";
    baseURL = "https://new-api.publicvm.com/v1";
    env = "OPENAI_API_KEY_ZZZ";
    sk = "LLM_Sub2API_zzz";
  };

  # https://linux.do/t/topic/1841046
  # https://freeapi.dgbmc.top/console/
  dgb = {
    baseURL = "https://freeapi.dgbmc.top/v1";
    env = "OPENAI_API_KEY_DGB";
    sk = "LLM_Sub2API_dgb";
  };

  # https://linux.do/t/topic/1845022
  # https://windhub.cc/console/
  ark = {
    baseURL = "https://windhub.cc/v1";
    env = "OPENAI_API_KEY_ARK";
    sk = "LLM_Sub2API_ark";
  };

  # https://linux.do/t/topic/1855760
  # https://free.9e.nz/dashboard
  kkk = {
    baseURL = "https://free.9e.nz/v1";
    env = "OPENAI_API_KEY_KKK";
    sk = "LLM_Sub2API_default";
  };

  # https://codex.mqc.me/dashboard
  mqc = {
    baseURL = "https://claude.colin1112.tech/v1";
    env = "OPENAI_API_KEY_MQC";
    sk = "LLM_Sub2API_mqc";
  };

  # https://linux.do/t/topic/1853293
  # https://muyuan.do/console/
  jun = {
    baseURL = "https://muyuan.do/v1";
    env = "OPENAI_API_KEY_JUN";
    sk = "LLM_Sub2API_jun";
  };

  # https://elysiver.h-e.top/console
  ely = {
    # base_url = "https://elysia.h-e.top/v1";
    baseURL = "https://elysiver.h-e.top/v1";
    env = "OPENAI_API_KEY_ELY";
    sk = "LLM_Sub2API_ely";
  };

  # https://api.42w.shop/console
  w42 = {
    baseURL = "https://api.42w.shop/v1";
    env = "OPENAI_API_KEY_W42";
    sk = "LLM_Sub2API_w42";
  };
}
