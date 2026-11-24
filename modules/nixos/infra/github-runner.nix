{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.github-runner;
  # This is exactly the upstream module's StateDirectory
  # (%S/github-runner/<name>): writable under ProtectSystem=strict.
  runnerHome = "/var/lib/github-runner/${cfg.name}";
in
{
  options.modules.infra.github-runner = {
    enable = lib.mkEnableOption "GitHub Actions self-hosted runner for fleet deploy (A1)";

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/xbpk3t/dotfiles";
      description = "Repository URL the runner registers to.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "fleet-control";
      description = "Runner name and attribute key under services.github-runners.";
    };

    labels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "fleet-control" ];
      description = "Extra runner labels; workflow targets [self-hosted, linux, x64] + these.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.github-runner = { };

    users.users.github-runner = {
      isSystemUser = true;
      group = "github-runner";
      home = runnerHome;
      createHome = true;
      # The nix-daemon socket is world-accessible on these hosts; no extra
      # group is required for `nix flake check` / `nix run`.
      shell = pkgs.bash;
    };

    # Dedicated credentials, owned by the runner user.
    # Intentionally module-local (not in secrets/defs.nix): only the runner host
    # declares them, so other hosts never request these keys from sops.
    # Keys must exist in secrets/secrets.yaml:
    #   github/runner_token    fine-grained PAT with Administration: write
    #   github/runner_ssh_key  existing nixos-vps-agt-deploy private key
    #
    # The matching public key is already in globals.auth.deployKeys, so NixOS
    # VPS root/luck already trust it. sm-vps nodes are currently auto=false; if
    # they are re-enabled, authorize the same public key on luck there.
    #
    # SECURITY: this key is trusted as root/luck on every fleet host, so the
    # runner is a fleet-wide root credential holder. Prefer a dedicated non-root
    # deploy user, and authorize the key with restrictions such as
    # `restrict,from="<runner tailnet IP>"` in authorized_keys.
    sops.secrets.GITHUB_RUNNER_TOKEN = {
      key = "github/runner_token";
      owner = "github-runner";
      group = "github-runner";
      mode = "0400";
      # PAT 轮换后必须重启 runner；否则单元继续使用启动时读到的旧 token。
      # SSH key 不需要：ssh 每次连接都会重新读取 IdentityFile。
      # sops-nix 需要完整 unit 名（含 .service），否则激活时报
      # "Unit name github-runner-<name> is not valid" 并触发 deploy-rs 回滚。
      restartUnits = [ "github-runner-${cfg.name}.service" ];
    };
    sops.secrets.GITHUB_RUNNER_SSH_KEY = {
      key = "github/runner_ssh_key";
      owner = "github-runner";
      group = "github-runner";
      mode = "0400";
    };

    services.github-runners.${cfg.name} = {
      enable = true;
      inherit (cfg) url;
      inherit (cfg) name;
      tokenFile = config.sops.secrets.GITHUB_RUNNER_TOKEN.path;
      # Non-ephemeral tokenFile runners only reconfigure when the token/config
      # changes, so --replace is not a per-boot re-registration. It just lets a
      # rotated token replace the existing runner registration.
      replace = true;
      # Non-ephemeral first: fewer moving parts. Flip to true only with a
      # renewable token source and a measured registration cost.
      ephemeral = false;
      extraLabels = cfg.labels;

      user = "github-runner";
      group = "github-runner";

      extraPackages = [
        config.nix.package
        pkgs.git
        pkgs.openssh
        pkgs.gh
        pkgs.go-task
        pkgs.nushell
        pkgs.ansible
        pkgs.jq
        pkgs.curl
        pkgs.coreutils
      ];

      # Upstream sets HOME=workDir (a cleaned RuntimeDirectory) first and merges
      # extraEnvironment last; override it with the persistent StateDirectory so
      # ~/.ssh/config, known_hosts and the Nix cache are writable under
      # ProtectSystem=strict.
      extraEnvironment = {
        HOME = runnerHome;
      };
    };

    # deploy-rs uses the runner user's SSH config. The identity is a
    # sops-rendered file under /run/secrets; known_hosts is TOFU within the
    # tailnet (matching the rest of the fleet). Pin known_hosts later if the
    # threat model requires it.
    system.activationScripts.github-runner-ssh = {
      deps = [
        "users"
        "groups"
      ];
      text = ''
        runner_home=${runnerHome}
        install -d -m 0700 -o github-runner -g github-runner /var/lib/github-runner
        install -d -m 0700 -o github-runner -g github-runner "$runner_home"
        install -d -m 0700 -o github-runner -g github-runner "$runner_home/.ssh"
        cat > "$runner_home/.ssh/config" <<'EOF'
        Host *
          IdentityFile ${config.sops.secrets.GITHUB_RUNNER_SSH_KEY.path}
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new
          UserKnownHostsFile ${runnerHome}/.ssh/known_hosts
          BatchMode yes
        EOF
        chown github-runner:github-runner "$runner_home/.ssh/config"
        chmod 0600 "$runner_home/.ssh/config"
      '';
    };
  };
}
