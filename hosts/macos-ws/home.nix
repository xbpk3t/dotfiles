{ mylib, ... }: {
  imports = [
    (mylib.relativeToRoot "secrets/default.nix")
    (mylib.relativeToRoot "home/core")
    (mylib.relativeToRoot "home/darwin")
  ];

  modules = {
    infra = {
      basePackages.enable = true;
      android.enable = false;
      nix-tools.enable = true;
      nh.enable = true;
      networking.enable = true;
    };

    kernel = {
      basePackages.enable = true;
      disk.enable = true;
      gpg.enable = true;
      network.enable = true;
      ssh.enable = true;
    };

    devops = {
      basePackages.enable = true;
      cf.enable = true;
      helix.enable = true;
      rclone.enable = true;
      tf = {
        enable = true;
        opentofu.enable = true;
        terramate.enable = true;
        lint.enable = true;
        ansible.enable = true;
      };
      yazi.enable = true;
      ssh = {
        enable = true;
      };
      # PR TUI（nixpkgs）+ review-first diff（herdr-reviewr plugin）；herdr keys: ctrl+alt+p / d
      hunk.enable = false;
      # fastfetch 在 Darwin 会拉入 apple-sdk-15.5（~481M 独有闭包），默认关闭；
      # 需要 fetcher 时打开。
      fastfetch.enable = false;
    };

    desktop = {
      stylix.enable = true;

      # Host plan during herdr trial: cmux remains daily Terminal/cockpit.
      # Ghostty wide window was the preferred herdr host in eval — flip when ready;
      # do not force herdr into GoLand narrow terminal.
      ghostty.enable = false;

      zed.enable = true;
    };

    AI = {
      codex.enable = false;
      claude.enable = true;
      # dsh 配置走 ~/.dsh/cordis.patch.yml（home 层），见 home/base/AI/dsh.nix
      dsh.enable = false;

      dagu = {
        enable = true;
        # 单机只需要月历 DAG，不需要把健康检查端口暴露到所有接口。
        schedulerPort = 0;
      };

      skills.enable = true;
      mcp.isDesktop = true;
    };

    langs = {
      basePackages.enable = true;
      golang.enable = true;
      markdown.enable = true;
      python.enable = true;
      rust.enable = true;
      treefmt.enable = true;
      ts.enable = true;
      lsp.enable = true;
    };

    ms = {
      gateway = {
        enable = true;
        caddy.enable = true;
        grpc.enable = true;
      };
      docker-cli.enable = true;
      colima.enable = true;
    };

    zzz.enable = true;
    darwin.basePackages.enable = true;
    darwin.default-apps.enable = true;
  };
}
