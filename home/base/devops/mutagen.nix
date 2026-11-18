{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.mutagen;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # One `ensure_sync` call per session.  The hash changes whenever the
  # session configuration changes, which makes the ensure script recreate
  # the session instead of silently keeping stale flags.
  mkEnsureCall =
    name: sync:
    let
      desiredHash = builtins.hashString "sha256" (
        builtins.toJSON {
          inherit (sync)
            alpha
            beta
            mode
            ignore
            ignoreVCS
            extraArgs
            gitignore
            ;
        }
      );
      args = [
        "--mode=${sync.mode}"
      ]
      ++ lib.optional sync.ignoreVCS "--ignore-vcs"
      ++ map (i: "--ignore=${i}") sync.ignore
      ++ sync.extraArgs;
    in
    ''
      ensure_sync ${lib.escapeShellArg name} ${lib.escapeShellArg desiredHash} \
        ${lib.escapeShellArg sync.alpha} ${lib.escapeShellArg sync.beta} \
        ${lib.boolToString sync.gitignore} ${lib.escapeShellArgs args}
    '';

  # Mutagen has no Home Manager module, so keep the declarative surface here:
  # a single idempotent script + one launchd/systemd timer.  The daemon is
  # started by the script and persists; the timer acts as a watchdog.
  ensureScript = pkgs.writeShellApplication {
    name = "mutagen-sync-ensure";
    runtimeInputs = [
      cfg.package
      pkgs.coreutils
      pkgs.git
      pkgs.gnugrep
      pkgs.gnused
      pkgs.openssh
    ];
    text = ''
      set -eu
      export MUTAGEN_SSH_PATH="${pkgs.openssh}/bin"

      # launchd agents don't inherit the login shell's SSH agent socket.
      # Pull it from launchd when available; harmless on Linux.
      if [ -z "''${SSH_AUTH_SOCK:-}" ] && [ -x /bin/launchctl ]; then
        SSH_AUTH_SOCK="$(/bin/launchctl getenv SSH_AUTH_SOCK || true)"
        export SSH_AUTH_SOCK
      fi

      state_dir="${config.xdg.stateHome}/mutagen-sync"
      mkdir -p "$state_dir"

      # Idempotent: starts the daemon only when it is not already running.
      mutagen daemon start >/dev/null 2>&1 || true

      # Wait for the daemon socket after login / reboot.
      for _ in $(seq 1 30); do
        if mutagen sync list >/dev/null 2>&1; then
          break
        fi
        sleep 1
      done

      # Mutagen has no native .gitignore support.  Read tracked .gitignore
      # files and convert them to --ignore flags: nested patterns containing
      # a slash are rebased onto their directory, leaf patterns stay global.
      collect_gitignore_patterns() {
        repo="$1"
        git -C "$repo" ls-files --cached -- '**/.gitignore' '.gitignore' 2>/dev/null |
          while IFS= read -r file; do
            [ -f "$repo/$file" ] || continue
            dir="$(dirname "$file")"
            [ "$dir" = "." ] && dir=""
            while IFS= read -r line; do
              line="''${line%$'\r'}"
              line="$(printf '%s' "$line" | sed 's/[[:space:]]*$//')"
              [ -z "$line" ] && continue
              case "$line" in \#*) continue ;; esac
              neg=""
              case "$line" in \!*) neg="!"; line="''${line#!}" ;; esac
              [ -z "$line" ] && continue
              case "$line" in
                */*)
                  [ -n "$dir" ] && line="$dir/''${line#/}"
                  ;;
              esac
              printf '%s%s\n' "$neg" "$line"
            done < "$repo/$file"
          done
      }

      ensure_sync() {
        name="$1"
        desired_hash="$2"
        alpha="$3"
        beta="$4"
        use_gitignore="$5"
        shift 5

        ignore_args=()
        if [ "$use_gitignore" = "true" ]; then
          gitignore_patterns="$(collect_gitignore_patterns "$alpha")"
          if [ -z "$gitignore_patterns" ]; then
            echo "mutagen: no tracked .gitignore patterns found for $name; refusing to create session" >&2
            return 1
          fi
          while IFS= read -r pattern; do
            [ -n "$pattern" ] && ignore_args+=("--ignore=$pattern")
          done <<< "$gitignore_patterns"
          gitignore_hash="$(printf '%s' "$gitignore_patterns" | sha256sum | cut -d' ' -f1)"
          desired_hash="$desired_hash-$gitignore_hash"
        fi

        hash_file="$state_dir/$name.hash"
        current_hash="$(cat "$hash_file" 2>/dev/null || true)"
        sessions="$(mutagen sync list --template '{{range .}}{{.Name}};{{end}}' 2>/dev/null || true)"
        count="$(printf '%s' "$sessions" | grep -o -F "$name;" | wc -l || true)"

        if [ "$count" -eq 1 ] && [ "$current_hash" = "$desired_hash" ]; then
          echo "mutagen: $name is already configured"
          return 0
        fi

        echo "mutagen: recreating $name (sessions=$count)"
        mutagen sync terminate "$name" >/dev/null 2>&1 || true
        mutagen sync create --name="$name" "$@" "''${ignore_args[@]}" "$alpha" "$beta"
        printf '%s' "$desired_hash" > "$hash_file"
      }

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkEnsureCall cfg.syncs)}
    '';
  };
in
{
  options.modules.devops.mutagen = with lib; {
    enable = mkEnableOption "Mutagen daemon + declarative sync sessions";

    package = mkPackageOption pkgs "mutagen" { };

    interval = mkOption {
      type = types.int;
      default = 300;
      description = "Seconds between ensure-script runs.";
    };

    syncs = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            alpha = mkOption {
              type = types.str;
              description = "Alpha endpoint (local path).";
            };

            beta = mkOption {
              type = types.str;
              description = "Beta endpoint (e.g. host:/absolute/path).";
            };

            mode = mkOption {
              type = types.enum [
                "two-way-safe"
                "two-way-resolved"
                "one-way-safe"
                "one-way-replica"
              ];
              default = "two-way-safe";
            };

            ignore = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Mutagen ignore patterns (gitignore-like syntax).";
            };

            ignoreVCS = mkOption {
              type = types.bool;
              default = true;
              description = "Ignore VCS directories such as .git.";
            };

            gitignore = mkOption {
              type = types.bool;
              default = false;
              description = "Read tracked .gitignore files from alpha and pass them as ignores.";
            };

            extraArgs = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Extra arguments passed to `mutagen sync create`.";
            };
          };
        }
      );
      default = { };
      description = "Sessions to ensure; the attribute name is the Mutagen session name.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    launchd.agents = lib.mkIf (isDarwin && cfg.syncs != { }) {
      mutagen-sync = {
        enable = true;
        config = {
          ProgramArguments = [ "${ensureScript}/bin/mutagen-sync-ensure" ];
          RunAtLoad = true;
          StartInterval = cfg.interval;
          ProcessType = "Background";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mutagen-sync.out.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mutagen-sync.err.log";
        };
      };
    };

    systemd.user.services = lib.mkIf (!isDarwin && cfg.syncs != { }) {
      mutagen-sync = {
        Unit.Description = "Ensure Mutagen sync sessions";
        Service = {
          Type = "oneshot";
          ExecStart = "${ensureScript}/bin/mutagen-sync-ensure";
        };
      };
    };

    systemd.user.timers = lib.mkIf (!isDarwin && cfg.syncs != { }) {
      mutagen-sync = {
        Unit.Description = "Periodically ensure Mutagen sync sessions";
        Timer = {
          Unit = "mutagen-sync.service";
          OnBootSec = "1min";
          OnUnitInactiveSec = "${toString cfg.interval}s";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
