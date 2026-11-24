{
  config,
  globals,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.ocr;
in
{
  # host:
  #   modules.AI.ocr.enable = true;
  #
  # Package: inputs.llm-agents（Go from-source build；cache.numtide.com 有缓存）。
  # llm-agents 里包名是 open-code-review，安装后的二进制名是 ocr。
  options.modules.AI.ocr = with lib; {
    enable = mkEnableOption "OpenCodeReview (ocr) AI code review CLI";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.open-code-review
    ];

    # 声明式接管 ~/.opencodereview/config.json
    # schema: alibaba/open-code-review → pages/src/content/docs/en/configuration.md
    home.file.".opencodereview/config.json" = {
      force = true;
      source = (pkgs.formats.json { }).generate "ocr-config.json" {
        provider = "axonhub";

        # 走 Anthropic 协议，与 claude.nix 的 ANTHROPIC_BASE_URL 同一端点；
        # codex/opencode 用 OpenAI 兼容 /v1，这里不跟着换协议。
        custom_providers.axonhub = {
          url = globals.llmGateway;
          protocol = "anthropic";
          model = globals.models.dsf;

          # 自定义 provider 没有环境变量回退，必须显式给凭据。
          # 用 api_key_cmd 在运行时读 sops 解密后的文件，明文不进 Nix store。
          api_key_cmd = "cat \"${config.sops.secrets.LLM_AxonHub.path}\"";

          # 单请求 HTTP 超时（秒）。高 effort + 大 prompt 下默认 300s 偏紧。
          timeout_sec = 600;
          # 网关若把限流表达成非标准 4xx，可加 retry_codes = [ 403 ]; 当前未观察到。
        };

        # 单个子任务（一个文件或一组相关文件）的 prompt 上限。
        # 内置默认 review=200k / scan=58,888；dsf 有 1M 上下文，抬到 400k。
        # 只影响输入预算，输出上限仍是模板里的 MAX_COMPLETION_TOKENS=16384。
        max_tokens = 400000;

        # 每个子任务的 review 轮数：low=1 / medium=2 / high=3。
        # 与 claude 的 max effort、codex 的 xhigh 取向一致；成本也相应更高。
        effort = "high";

        # review 评论语言。
        language = "中文";

        # 默认就是关闭；显式写出来，避免未来默认值变化或误开 OCR_ENABLE_TELEMETRY。
        telemetry.enabled = false;

        # mcp_servers 暂不接。MCP 对 ocr 是可选的（只用于 ocr review，scan 不连），
        # 而 programs.mcp.servers 的鉴权形状与 ocr 不兼容：stdio server 的身份靠
        # passwordCommand wrapper 注入（能平移），但 hosted HTTP server 的
        # bearer_token_env_var 在 ocr 里没有对应字段，直接平移会变成无鉴权连接。
        # 需要时按 server 显式写 headers，不要做半套复用。

        # 旧版单端点配置（llm.*）不使用：已由 custom_providers.axonhub 接管，
        # 保存的 provider 优先于 OCR_LLM_* / ANTHROPIC_* 环境变量。
      };
    };
  };
}
