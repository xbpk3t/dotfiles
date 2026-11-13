{
  config,
  globals,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.dsh;

  # ── 为什么是 home 层，而不是 profile 层 ────────────────────────────────────
  # dsh 的配置是「patch 栈」：bundle → profile 的 cordis.patch.yml → home 层
  # ($DSH_HOME/cordis.patch.yml) → --patch。前两层归 app 所有：
  #   - desktop profile 被 Electron 独占，CLI 直接拒绝操作；
  #   - 各前端的设置页会把改动原子写回 profile 层的 patch 文件（先写临时文件再
  #     rename，rename 会把软链替换成普通文件），所以 profile 层不能交给 nix。
  # home 层没有任何程序会写它（Electron 的崩溃恢复也只动 profile 层），优先级
  # 又最高，因此是唯一适合 nix 托管的接缝。代价：被 home 层覆盖的字段在设置页
  # 变成只读（写入会被拒绝）。这里只放「策略层」，UI 偏好留给 profile 层。
  #
  # ── 为什么产物是 JSON 而不是 YAML ─────────────────────────────────────────
  # JSON 是 YAML 1.2 的严格子集，dsh 的 js-yaml 直接解析（已用 --dump-config
  # 实测：JSON 内容放进 cordis.patch.yml 能正常组合）。这样可以避开 nix 侧
  # YAML 生成器对「顶层是 list 的 patch 文档」支持不一致的问题，也不必自己写
  # 序列化。代价：store 里的文件没有注释、不可读 —— 可读视图用
  #   dsh --profile <name> --dump-config
  # 刻意不使用 !!js：YAML 自定义 tag 无法由通用生成器输出，且这里的两个用途
  # 都可以避开（路径用绝对路径、secret 用 credential 模板）。

  # MCP server 声明复用 mcp.nix 里那一份（cc / codex 也吃同一份），保证三端
  # 不漂移。flavor 保持 codex：它只是输出通用形状 + codex 专有字段。
  mcpServers =
    (inputs.mcp-servers-nix.lib.evalModule pkgs {
      inherit (config.mcp-servers) programs settings;
      flavor = "codex";
    }).config.settings.servers;

  # dsh-mcp-client 只认 stdio / streamable-http，也没有 codex 的审批字段
  # （default_tools_approval_mode / tools.*.approval_mode）：本机是
  # danger-full-access + never，审批本来就不参与，直接丢掉。
  mcpRow =
    name: server:
    let
      isHttp = (server.type or null) == "http";
      # codex 用 bearer_token_env_var 指定鉴权变量名；dsh 没有 OAuth fallback，
      # 只能显式 header —— 由 expandTemplates 在请求时把 ${credential:...}
      # 解析成真实密钥（凭据库 → 启动环境 → 项目 .env → ~/.dsh/.env）。
      bearerEnv = server.bearer_token_env_var or (if name == "linear" then "LINEAR_API_KEY" else null);
      timeoutSec = server.startup_timeout_sec or null;
    in
    {
      id = "mcp-${name}";
      name = "@deepseek-ai/dsh-mcp-client";
      config = {
        serverName = name;
        transport = if isHttp then "streamable-http" else "stdio";
      }
      // lib.optionalAttrs isHttp {
        inherit (server) url;
        headers =
          (server.headers or { })
          // lib.optionalAttrs (bearerEnv != null) {
            Authorization = "Bearer \${credential:${bearerEnv}}";
          };
        expandTemplates = true;
      }
      // lib.optionalAttrs (!isHttp) {
        inherit (server) command;
        args = server.args or [ ];
        env = server.env or { };
      }
      // lib.optionalAttrs (timeoutSec != null) {
        startupTimeoutMs = timeoutSec * 1000;
      };
    };

  homePatch = [
    # 随附的 base / web 组合都没有挂 mcp-client（也没有 MCP 设置页），只能 insert。
    { insert = builtins.attrValues (builtins.mapAttrs mcpRow mcpServers); }

    # 沙箱与审批：与 codex.nix 一致的本机全自动档。
    # 注意：这一行覆盖后，图形界面的权限切换器会被压住（预期内）。
    {
      id = "sandbox-policy";
      config = {
        mode = "danger-full-access";
      };
    }
    {
      id = "approval";
      config = {
        policy = "never";
      };
    }

    # 默认 FEEDBACK_ONLY 会把明确反馈的会话前缀上报到 dsh-otel-collector；
    # 用配置行关掉（DSH_TELEMETRY_DISABLED 是 env，Dock 启动的 GUI 继承不到）。
    {
      id = "session-telemetry-otel";
      config = {
        mode = "DISABLED";
      };
    }

    # 默认 :memory: + openAt: never，侧栏只能按标题搜。改成持久 SQLite。
    {
      id = "session-query-sqlite";
      config = {
        path = "${config.home.homeDirectory}/.dsh/cache/session-query.sqlite";
        openAt = "first-search";
      };
    }

    # 模型路由：放在 home 层，新 profile（web / dsh-tui）不用先在设置页点一遍
    # 就有 axonhub 可用。代价是设置页的 Models 页面对该行只读。
    {
      id = "llm-pi-ai";
      config = {
        providers.axonhub = {
          apiKeyEnv = "AXONHUB_API_KEY";
          api = "openai-completions";
          baseURL = "https://api.lucc.dev/v1";
          models = [
            {
              id = globals.models.dsf;
              name = globals.models.dsf;
            }
          ];
        };
      };
    }
    {
      id = "agent-default-model";
      config = {
        provider = "axonhub";
        model = globals.models.dsf;
      };
    }
  ];
in
{
  options.modules.AI.dsh = with lib; {
    enable = mkEnableOption "Enable DeepSeek Harness (dsh) declarative config";
  };

  config = lib.mkIf cfg.enable {
    # 只托管 home 层这一个配置文件；profile 目录、凭据库、sessions/storages
    # 全部留给 app（它们都是运行时状态或被 app 原子改写）。
    home.file.".dsh/cordis.patch.yml" = {
      force = true;
      source = pkgs.writeText "dsh-home-cordis.patch.json" (builtins.toJSON homePatch);
    };

    # linear 这类 remote HTTP MCP 没有 OAuth，只能显式 Bearer token；token 走
    # sops 在激活时渲染成 ~/.dsh/.env（与 rclone.conf 同一模式），不进 store。
    # dsh 的 .env 分层：启动环境 > 项目 .env > 本文件，且 DSH_* / XDG_* 会被
    # 拒绝加载（bootstrap-only），普通变量没问题。
    sops.templates."dsh-env".content = ''
      LINEAR_API_KEY=${config.sops.placeholder.API_LINEAR}
      AXONHUB_API_KEY=${config.sops.placeholder.LLM_AxonHub}
    '';

    home.file.".dsh/.env" = {
      force = true;
      # eval 时 sops 渲染路径还不存在，必须走 out-of-store 软链（同 rclone）。
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."dsh-env".path;
    };
  };
}
