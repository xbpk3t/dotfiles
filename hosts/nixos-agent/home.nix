{
  config,
  lib,
  pkgs,
  ...
}: {
  # Agent 容器只包含 AI 工具链，不含任何桌面/IDE/图形组件

  # headless 环境下 gh auth login 不可用，通过 sops secret 注入 token
  # mkForce：覆盖 zsh.nix 中 GITHUB_TOKEN="$(gh auth token)" 的动态获取（容器无 gh auth 登录态）
  home.sessionVariables = {
    GITHUB_TOKEN = lib.mkForce "$(cat ${config.sops.secrets.GITHUB_TOKEN.path})";
  };

  modules = {
    AI = {
      claude = {
        enable = true;
        permissionMode = "yolo";
      };
      skills.enable = true;
    };
    infra = {
      nh.enable = true;
      networking.enable = true;
    };
  };

  home.packages = with pkgs; [
    # 容器调试工具
    htop
    iotop
    lsof
    tcpdump
    # ClaudeClaw daemon 运行时（bun run src/index.ts start）
    bun
    # ClaudeClaw 的 OGG 转换 helper 需要 Node.js（独立于 bun）
    nodejs_22
  ];

  # [2026-05-25] ClaudeClaw heartbeat daemon 自启动
  # 容器 reboot 后自动拉起 daemon，无需手动 SSH 进来 /claudeclaw:start。
  # daemon 启动时从 ~/.claude/plugins/cache 自动发现最新版本路径。
  #
  # 鸡生蛋问题：ClaudeClaw 插件缓存是 Claude Code 首次运行时的异步同步产物。
  # 全新容器或缓存目录存在但为空（上一次同步被中断）时，systemd daemon 会
  # 因为插件入口缺失而永久重启死循环——没有任何东西会替它跑第一次 claude。
  # 解决：检测到插件入口（src/index.ts）缺失时，先跑一次 headless claude
  # --print 触发完整插件同步（30s 超时兜底），确保就绪后再启动 daemon。
  # 注意：不能只判目录存在（空目录可能被前次中断的同步留下），必须判入口文件。
  # [2026-05-26] ClaudeClaw 的setup有点复杂，应该手动去跑，而非自启动，所以注释掉了。仅供参考。
  #  systemd.user.services.claudeclaw-daemon = {
  #    Unit = {
  #      Description = "ClaudeClaw heartbeat daemon";
  #      After = ["network-online.target"];
  #      Wants = ["network-online.target"];
  #    };
  #    Service = {
  #      Type = "simple";
  #      WorkingDirectory = "%h/Desktop/docs";
  #      ExecStart = "${pkgs.writeShellApplication {
  #        name = "claudeclaw-daemon-start";
  #        runtimeInputs = with pkgs; [findutils coreutils bun util-linux];
  #        text = ''
  #          CACHE="$HOME/.claude/plugins/cache/claudeclaw/claudeclaw"
  #
  #          latest() {
  #            find "$CACHE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
  #              | sort -V | tail -1
  #          }
  #
  #          LATEST=$(latest)
  #          if [ -z "$LATEST" ] || [ ! -f "$LATEST/src/index.ts" ]; then
  #            echo "claudeclaw plugin entry not found, bootstrapping via headless Claude..."
  #            # systemd user service 不继承 home.sessionVariables，
  #            # Claude Code 所需的 ANTHROPIC_* 和 GITHUB_TOKEN 必须显式注入。
  #            #
  #            # 设计说明：为什么 ANTHROPIC_BASE_URL 用公网 URL 而非本地 Docker IP？
  #            #   （同上，见前面注释块）
  #            ANTHROPIC_BASE_URL="https://api.lucc.dev"
  #            export ANTHROPIC_BASE_URL
  #            ANTHROPIC_AUTH_TOKEN="$(cat ${config.sops.secrets.LLM_AxonHub.path})"
  #            export ANTHROPIC_AUTH_TOKEN
  #            GITHUB_TOKEN="$(cat ${config.sops.secrets.GITHUB_TOKEN.path})"
  #            export GITHUB_TOKEN
  #            # Claude Code 在无 TTY 环境下（systemd service）不会完成完整的
  #            # 插件初始化流程，导致缓存被标记为 .orphaned_at。用 script(1) 提供
  #            # 伪终端，确保插件同步（GitHub 下载）等异步初始化能完整执行。
  #            CLAUDE="${config.programs.claude-code.package}/bin/claude"
  #            script -q -c "timeout 120 $CLAUDE --print hello --permission-mode bypassPermissions" /dev/null 2>&1 || true
  #            LATEST=$(latest)
  #          fi
  #
  #          if [ -z "$LATEST" ] || [ ! -f "$LATEST/src/index.ts" ]; then
  #            echo "plugin entry still missing after bootstrap"
  #            exit 1
  #          fi
  #          echo "Starting ClaudeClaw daemon from $LATEST"
  #          exec bun run "$LATEST/src/index.ts" start
  #        '';
  #      }}/bin/claudeclaw-daemon-start";
  #      Restart = "on-failure";
  #      RestartSec = 30;
  #    };
  #    Install = {
  #      WantedBy = ["default.target"];
  #    };
  #  };
}
