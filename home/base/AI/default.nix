{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  linearApiKeyPrelude = ''
    if [ -z "''${LINEAR_API_KEY:-}" ] && [ -r ${lib.escapeShellArg config.sops.secrets.API_LINEAR.path} ]; then
      LINEAR_API_KEY="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.API_LINEAR.path})"
      export LINEAR_API_KEY
    fi
  '';
in {
  imports = [
    ./mcp.nix
    ./codex.nix
    ./claude.nix
    ./opencode.nix
    ./skills.nix
  ];

  # MAYBE: [2026-04-21] 之后再判断是否要添加 rtk
  # https://github.com/rtk-ai/rtk
  # https://mynixos.com/nixpkgs/package/rtk 注意 llm-agents 本身支持 rtk
  # https://x.com/laogui/status/2045677115341934867
  # https://x.com/djdksnel/status/2044612252503011832
  # https://x.com/djdksnel/status/2045739787831881847
  # 暂不考虑添加 rtk，因为侵入性太强
  # 1) 要发挥 rtk 的核心价值（命令自动重写），必须接入 Claude 的 PreToolUse hook。
  # 2) 当前仓库已通过 programs.claude-code.settings 声明式管理 ~/.claude/settings.json，叠加 rtk init -g 产物会造成双源配置与行为冲突。
  # 3) hook 脚本需要长期跟踪 upstream 变更，维护和排障成本高于普通静态配置文件。
  # 4) 在没有明确收益数据前，先保持 AI 工具链行为可预测，避免引入全局命令改写副作用。

  home.packages =
    (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      # https://github.com/microsoft/apm
      apm
    ])
    ++ [
      (pkgs.writeShellApplication {
        name = "linear-finalize";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.jujutsu
          pkgs.nushell
        ];
        text = ''
          ${linearApiKeyPrelude}

          issue="''${LINEAR_FINALIZE_ISSUE:-}"
          agent="''${LINEAR_FINALIZE_AGENT:-''${LINEAR_AGENT:-agent}}"
          model="''${LINEAR_FINALIZE_MODEL:-''${LINEAR_MODEL:-unknown}}"
          session_id="''${LINEAR_FINALIZE_SESSION_ID:-''${LINEAR_SESSION_ID:-unknown}}"
          transcript_path="''${LINEAR_FINALIZE_TRANSCRIPT_PATH:-}"
          cwd="''${LINEAR_FINALIZE_CWD:-$PWD}"
          body_file="''${LINEAR_FINALIZE_BODY_FILE:-}"
          base="''${LINEAR_FINALIZE_BASE:-origin/main}"
          dry_run="''${LINEAR_FINALIZE_DRY_RUN:-0}"
          keep_checkpoints="''${LINEAR_FINALIZE_KEEP_CHECKPOINTS:-0}"

          usage() {
            cat <<'EOF'
          Usage: linear-finalize [options] < review.md

          Options:
            --issue LUC-XXX           Override issue key. Defaults to luc/LUC-XXX branch detection.
            --agent NAME              codex, claude-code, or another agent label.
            --model MODEL             Model label written to Linear metadata.
            --session-id ID           Session id written to Linear metadata.
            --transcript-path PATH    Transcript path written to Linear metadata.
            --cwd PATH                Repository cwd. Defaults to current directory.
            --body-file PATH          Read review body from file instead of stdin.
            --base REF                Base ref for commit facts. Defaults to origin/main.
            --dry-run                 Print the comment instead of posting to Linear.
            --keep-checkpoints        Keep captured plan checkpoint files after posting.
          EOF
          }

          while [ "$#" -gt 0 ]; do
            case "$1" in
              --issue)
                shift
                issue="''${1:?--issue requires a value}"
                ;;
              --issue=*) issue="''${1#--issue=}" ;;
              --agent)
                shift
                agent="''${1:?--agent requires a value}"
                ;;
              --agent=*) agent="''${1#--agent=}" ;;
              --model)
                shift
                model="''${1:?--model requires a value}"
                ;;
              --model=*) model="''${1#--model=}" ;;
              --session-id)
                shift
                session_id="''${1:?--session-id requires a value}"
                ;;
              --session-id=*) session_id="''${1#--session-id=}" ;;
              --transcript-path)
                shift
                transcript_path="''${1:?--transcript-path requires a value}"
                ;;
              --transcript-path=*) transcript_path="''${1#--transcript-path=}" ;;
              --cwd)
                shift
                cwd="''${1:?--cwd requires a value}"
                ;;
              --cwd=*) cwd="''${1#--cwd=}" ;;
              --body-file)
                shift
                body_file="''${1:?--body-file requires a value}"
                ;;
              --body-file=*) body_file="''${1#--body-file=}" ;;
              --base)
                shift
                base="''${1:?--base requires a value}"
                ;;
              --base=*) base="''${1#--base=}" ;;
              --dry-run) dry_run=1 ;;
              --keep-checkpoints) keep_checkpoints=1 ;;
              -h|--help)
                usage
                exit 0
                ;;
              --)
                shift
                break
                ;;
              *)
                echo "linear-finalize: unknown option: $1" >&2
                usage >&2
                exit 2
                ;;
            esac
            shift
          done

          if [ "$#" -gt 0 ]; then
            echo "linear-finalize: unexpected positional arguments: $*" >&2
            usage >&2
            exit 2
          fi

          export LINEAR_FINALIZE_ISSUE="$issue"
          export LINEAR_FINALIZE_AGENT="$agent"
          export LINEAR_FINALIZE_MODEL="$model"
          export LINEAR_FINALIZE_SESSION_ID="$session_id"
          export LINEAR_FINALIZE_TRANSCRIPT_PATH="$transcript_path"
          export LINEAR_FINALIZE_CWD="$cwd"
          export LINEAR_FINALIZE_BODY_FILE="$body_file"
          export LINEAR_FINALIZE_BASE="$base"
          export LINEAR_FINALIZE_DRY_RUN="$dry_run"
          export LINEAR_FINALIZE_KEEP_CHECKPOINTS="$keep_checkpoints"

          if [ -n "$body_file" ] || [ -t 0 ]; then
            exec ${pkgs.nushell}/bin/nu --stdin -c 'source ${./hooks}/linear-finalize.nu' < /dev/null
          else
            exec ${pkgs.nushell}/bin/nu --stdin -c 'source ${./hooks}/linear-finalize.nu'
          fi
        '';
      })
      (pkgs.writeShellApplication {
        name = "linear-latest-post";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.jujutsu
          pkgs.nushell
        ];
        text = ''
          ${linearApiKeyPrelude}

          issue="''${LINEAR_LATEST_POST_ISSUE:-}"
          agent="''${LINEAR_LATEST_POST_AGENT:-''${LINEAR_AGENT:-agent}}"
          model="''${LINEAR_LATEST_POST_MODEL:-''${LINEAR_MODEL:-unknown}}"
          session_id="''${LINEAR_LATEST_POST_SESSION_ID:-''${LINEAR_SESSION_ID:-unknown}}"
          cwd="''${LINEAR_LATEST_POST_CWD:-$PWD}"
          body_file="''${LINEAR_LATEST_POST_BODY_FILE:-}"
          dry_run="''${LINEAR_LATEST_POST_DRY_RUN:-0}"
          body="''${LINEAR_LATEST_POST_BODY:-}"
          body_args=()

          usage() {
            cat <<'EOF'
          Usage: linear-latest-post [options] [content]
                 linear-latest-post [options] < body.md

          Options:
            --issue LUC-XXX        Override issue key. Defaults to luc/LUC-XXX branch detection.
            --agent NAME           codex, claude-code, or another agent label.
            --model MODEL          Model label written to Linear metadata.
            --session-id ID        Session id written to Linear metadata.
            --cwd PATH             Repository cwd. Defaults to current directory.
            --body-file PATH       Read body from file instead of stdin/content args.
            --dry-run              Print the comment instead of posting to Linear.
          EOF
          }

          while [ "$#" -gt 0 ]; do
            case "$1" in
              --issue)
                shift
                issue="''${1:?--issue requires a value}"
                ;;
              --issue=*) issue="''${1#--issue=}" ;;
              --agent)
                shift
                agent="''${1:?--agent requires a value}"
                ;;
              --agent=*) agent="''${1#--agent=}" ;;
              --model)
                shift
                model="''${1:?--model requires a value}"
                ;;
              --model=*) model="''${1#--model=}" ;;
              --session-id)
                shift
                session_id="''${1:?--session-id requires a value}"
                ;;
              --session-id=*) session_id="''${1#--session-id=}" ;;
              --cwd)
                shift
                cwd="''${1:?--cwd requires a value}"
                ;;
              --cwd=*) cwd="''${1#--cwd=}" ;;
              --body-file)
                shift
                body_file="''${1:?--body-file requires a value}"
                ;;
              --body-file=*) body_file="''${1#--body-file=}" ;;
              --dry-run) dry_run=1 ;;
              -h|--help)
                usage
                exit 0
                ;;
              --)
                shift
                while [ "$#" -gt 0 ]; do
                  body_args+=("$1")
                  shift
                done
                break
                ;;
              *) body_args+=("$1") ;;
            esac
            shift
          done

          if [ "''${#body_args[@]}" -gt 0 ]; then
            printf -v body '%s ' "''${body_args[@]}"
            body="''${body% }"
          fi

          export LINEAR_LATEST_POST_ISSUE="$issue"
          export LINEAR_LATEST_POST_AGENT="$agent"
          export LINEAR_LATEST_POST_MODEL="$model"
          export LINEAR_LATEST_POST_SESSION_ID="$session_id"
          export LINEAR_LATEST_POST_CWD="$cwd"
          export LINEAR_LATEST_POST_BODY_FILE="$body_file"
          export LINEAR_LATEST_POST_DRY_RUN="$dry_run"
          export LINEAR_LATEST_POST_BODY="$body"

          if [ -n "$body_file" ] || [ -n "$body" ] || [ -t 0 ]; then
            exec ${pkgs.nushell}/bin/nu --stdin -c 'source ${./hooks}/linear-latest-post.nu' < /dev/null
          else
            exec ${pkgs.nushell}/bin/nu --stdin -c 'source ${./hooks}/linear-latest-post.nu'
          fi
        '';
      })
    ];
}
