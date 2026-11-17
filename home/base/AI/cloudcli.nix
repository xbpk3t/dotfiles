{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.cloudcli;

  # npm 安装的 native addon（better-sqlite3 / node-pty / bcrypt）按 Node ABI 编译；
  # service 必须用同一大版本，所以安装和运行都锁到 pkgs.nodejs_24。
  nodejs = pkgs.nodejs_24;
  prefix = "${config.home.homeDirectory}/.local/share/cloudcli";

  # 不在 activation 里跑 npm（网络 + 1.5G）；首次启动自愈安装，之后直接 exec。
  launcher = pkgs.writeShellScript "cloudcli-launcher" ''
    set -eu
    prefix=${lib.escapeShellArg prefix}
    version=${lib.escapeShellArg cfg.version}
    package="$prefix/node_modules/@cloudcli-ai/cloudcli/package.json"

    installed=""
    if [ -f "$package" ]; then
      installed="$(${nodejs}/bin/node -e 'console.log(require(process.argv[1]).version)' "$package" 2>/dev/null || true)"
    fi

    if [ "$installed" != "$version" ]; then
      mkdir -p "$prefix"
      cd "$prefix"
      ${nodejs}/bin/npm install --no-audit --no-fund --loglevel=error "@cloudcli-ai/cloudcli@$version"
    fi

    exec "$prefix/node_modules/.bin/cloudcli" "$@"
  '';
in
{
  options.modules.AI.cloudcli = with lib; {
    enable = mkEnableOption "CloudCLI (Claude Code UI)";

    version = mkOption {
      type = types.str;
      default = "1.37.8";
      description = "Pinned @cloudcli-ai/cloudcli npm version.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address the CloudCLI server binds to.";
    };

    port = mkOption {
      type = types.port;
      default = 3001;
      description = "Port the CloudCLI server listens on.";
    };

    memoryHigh = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Optional systemd MemoryHigh for the CloudCLI server (e.g. "300M").
        Keep null to avoid affecting first-run npm install bursts.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    systemd.user.services.cloudcli = {
      Unit = {
        Description = "CloudCLI (Claude Code UI)";
        After = [
          "network.target"
          "sops-nix.service"
          "tailscaled.service"
        ];
      };

      Service = {
        ExecStart = "${launcher} start --port ${toString cfg.port}";
        Environment = [
          "HOME=${config.home.homeDirectory}"
          "HOST=${cfg.bindAddress}"
          "SERVER_PORT=${toString cfg.port}"
          "DATABASE_PATH=${config.home.homeDirectory}/.cloudcli/auth.db"
          # claude/codex/git/rg 都从 HM profile 或系统 PATH 取。
          "PATH=${nodejs}/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
          "SHELL=${pkgs.bash}/bin/bash"
        ];
        EnvironmentFile = config.sops.templates."cloudcli-env".path;
        WorkingDirectory = config.home.homeDirectory;
        Restart = "always";
        RestartSec = 5;
        # 首次启动可能触发 npm install（约 1.5G），给足时间。
        TimeoutStartSec = 900;
      }
      // lib.optionalAttrs (cfg.memoryHigh != null) { MemoryHigh = cfg.memoryHigh; };

      Install.WantedBy = [ "default.target" ];
    };

    # CloudCLI 的 provider 检测只读进程环境，不读 shell sessionVariables。
    # 把 Claude Code 的网关凭据和 OpenCode 的 provider key 显式注入：
    # - ANTHROPIC_AUTH_TOKEN 命中 Claude 的 api_key 分支，不会要求 claude /login
    # - AXONHUB_API_KEY 命中 OpenCode config 里的 {env:AXONHUB_API_KEY}
    # - OPENAI_API_KEY 仅用于 CloudCLI 1.37.8 的 OpenCode 状态探测
    #   （该版本只认固定 env 列表，不解析 opencode config；实际请求仍走 axonhub）
    #   故意放占位符而不是真 token：避免 OpenCode/Codex 选中 openai provider 时
    #   把 AxonHub key 发到第三方端点。
    sops.templates."cloudcli-env".content = ''
      ANTHROPIC_BASE_URL=https://api.lucc.dev
      ANTHROPIC_AUTH_TOKEN=${config.sops.placeholder.LLM_AxonHub}
      AXONHUB_API_KEY=${config.sops.placeholder.LLM_AxonHub}
      OPENAI_API_KEY=cloudcli-status-only
    '';
  };
}
