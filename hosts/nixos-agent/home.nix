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
  ];

  # [2026-05-25] ClaudeClaw heartbeat daemon 自启动
  # 容器 reboot 后自动拉起 daemon，无需手动 SSH 进来 /claudeclaw:start。
  # daemon 启动时从 ~/.claude/plugins/cache 自动发现最新版本路径，
  # 首次启动时若插件尚未同步（Claude 未 run 过），会每 30 秒重试直到成功。
  systemd.user.services.claudeclaw-daemon = {
    Unit = {
      Description = "ClaudeClaw heartbeat daemon";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h/Desktop/docs";
      ExecStart = pkgs.writeShellScript "claudeclaw-daemon-start" ''
        CACHE="$HOME/.claude/plugins/cache/claudeclaw/claudeclaw"
        if [ ! -d "$CACHE" ]; then
          echo "claudeclaw plugin not yet synced, retrying later..."
          exit 1
        fi
        LATEST=$(ls -d "$CACHE"/*/ 2>/dev/null | sort -V | tail -1)
        if [ -z "$LATEST" ]; then
          echo "no plugin version found in $CACHE"
          exit 1
        fi
        echo "Starting ClaudeClaw daemon from $LATEST"
        exec ${pkgs.bun}/bin/bun run "$LATEST/src/index.ts" start
      '';
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
