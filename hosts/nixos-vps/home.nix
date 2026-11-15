{
  config,
  hostMeta,
  lib,
  pkgs,
  ...
}:
let
  isAgent = hostMeta.role == "agent";
  isServer = !isAgent;
  tailnetIp = hostMeta.tailscale.ip or "127.0.0.1";

  proxyUrl = "http://127.0.0.1:7890";
  noProxy = "localhost,127.0.0.1,::1,100.64.0.0/10,10.0.0.0/8,192.168.0.0/16,198.18.0.0/16";

  # 备份 agt 上的项目、未提交 WIP 和 agent 状态到 R2（restic 仓库 rclone:r2:agt-backup）。
  # 排除 node_modules/.git 等可再生/体积大的内容；git 历史本身在 GitHub。
  backupScript = pkgs.writeShellScript "restic-backup-agt" ''
    export PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin
    exec ${pkgs.restic}/bin/restic -r rclone:r2:agt-backup backup \
      ${config.home.homeDirectory}/Desktop \
      ${config.home.homeDirectory}/.claude \
      ${config.home.homeDirectory}/.codex \
      ${config.home.homeDirectory}/.config/opencode \
      --password-file ${config.sops.secrets.RESTIC_PASSWORD.path} \
      --exclude .git --exclude node_modules --exclude apm_modules \
      --exclude dist --exclude public --exclude .DS_Store --tag agt
  '';

  # Server 角色：curated cockpit，不整包 import home/base。
  serverImports = [
    ../../home/base/devops/rclone.nix
    ../../home/base/devops/ghui.nix
    ../../home/base/devops/hunk.nix
    ../../home/base/devops/yazi.nix # file manager
    # helix.nix 在 let 层读取 modules.langs.lsp.packages，需要 lsp 的 option 定义。
    ../../home/base/langs/lsp.nix
    ../../home/base/devops/helix.nix # ghui/yazi/$EDITOR → hx
    ../../home/base/AI/claude.nix
    ../../home/base/AI/skills.nix
    ../../home/base/AI/dagu.nix
  ];

  # Agent 角色：完整 home/base + home/nixos。
  agentImports = [
    ../../home/base
    ../../home/nixos
  ];
in
{
  imports = if isAgent then agentImports else serverImports;

  config = lib.mkMerge [
    {
      modules = {
        infra = {
          nh.enable = true;
          networking.enable = true;
        };

        devops.ssh = {
          enable = isAgent;
          hosts = {
            github.enable = true;
            hk-hdy.enable = true;
          };
        };

        AI = {
          claude.enable = true;
          skills.enable = true;
          dagu = {
            enable = true;
            # 只跑 scheduler；web UI 已关闭。
            web.enable = false;
            # 避开 VPS 上 axonhub 的 8090 和给 qbittorrent 预留的 8080。
            host = tailnetIp;
            port = 8081;
            schedulerPort = 8091;
          };
        };
      };
    }

    (lib.mkIf isServer {
      modules.devops = {
        ghui.enable = true;
        hunk.enable = true;
      };

      # VPS 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入。
      home.sessionVariables.EDGE_NETWORK_EXTERNAL = "true";
    })

    # 这个 option 只在 agent 侧 import，server 上不能引用（mkIf false 也要求 option 已声明）。
    (lib.optionalAttrs isAgent {
      modules = {
        AI = {
          dsh.enable = true;

          opencli-browser = {
            enable = true;
            # x11vnc 绑 tailnet，Mac 可直接用 Screen Sharing 打开 vnc://100.66.22.92:5900。
            bindAddress = tailnetIp;
          };

          # opencode CLI 保留；web UI 已关闭。bind/port 保留，方便以后恢复。
          opencode = {
            enable = true;
            web = {
              enable = false;
              bindAddress = tailnetIp;
              port = 4096;
            };
          };

          # CloudCLI（Claude Code UI）：只绑 tailnet IP，应用自带登录。
          # Mac 访问 http://100.66.22.92:3001，首次访问注册单用户。
          cloudcli = {
            enable = true;
            bindAddress = tailnetIp;
            port = 3001;
          };
        };

        # Herdr core runtime：Mac/手机 herdr-app 通过 SSH(tailnet) 执行
        # `hc connect` 直连本机。不要用官方 install.sh 装到 ~/.local/bin，
        # 否则版本脱离 nix 管理；包由 inputs.llm-agents 提供。
        devops.herdr-core = {
          enable = true;
          # 程序丢失后在新 shell 上方显示最后屏幕；其余走 core 默认值。
          settings.restore_screen = true;
        };

      };
    })

    # Restic 备份：Desktop + agent state → R2。
    # dsh-web 已关闭；dsh CLI/config 仍由 AI.dsh.enable 提供。
    (lib.mkIf isAgent {
      home.packages = [ pkgs.restic ];

      systemd.user.services.restic-backup = {
        Unit = {
          Description = "Restic backup of Desktop + agent state to R2";
          After = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${backupScript}";
        };
      };

      systemd.user.timers.restic-backup = {
        Unit.Description = "Daily restic backup";
        Timer = {
          OnCalendar = "*-*-* 04:30:00";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };

    })

    # agt 在 Shanghai：mihomo TUN 对部分直连不可靠，显式给 DAG/CLI 设置 mixed-port 代理。
    # 本地/tailnet/私网走 NO_PROXY；github/google 等走 mihomo。
    (lib.mkIf isAgent {
      home.sessionVariables = {
        HTTP_PROXY = proxyUrl;
        HTTPS_PROXY = proxyUrl;
        ALL_PROXY = proxyUrl;
        NO_PROXY = noProxy;
        http_proxy = proxyUrl;
        https_proxy = proxyUrl;
        all_proxy = proxyUrl;
        no_proxy = noProxy;
      };
    })
  ];
}
