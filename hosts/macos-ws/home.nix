{ config, mylib, ... }: {
  imports = [
    (mylib.relativeToRoot "secrets/default.nix")
    (mylib.relativeToRoot "home/core")
    (mylib.relativeToRoot "home/darwin")
  ];

  modules = {
    infra = {
      basePackages.enable = true;
      android.enable = false;
      nix-tools = {
        enable = true;
        packaging.enable = true;
        analysis.enable = true;
      };
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
      cicd.enable = true;
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
      fetch = {
        enable = true;
        driver = "macchina";
      };
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
      golang = {
        enable = true;
        gotools.enable = true;
      };
      markdown.enable = true;
      pandoc.enable = true;
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
      helm.enable = true;
      docker-cli.enable = true;
      colima.enable = true;
    };

    sys.basePackages.enable = true;

    works = {
      crawler.enable = true;
      recon.enable = true;
      test.enable = true;
    };

    zzz.enable = true;
    darwin.basePackages.enable = true;
    darwin.default-apps.enable = true;
  };

  # docs 只在本机 opt-in；core 只保留 services.git-sync.enable 开关。
  # launchd 默认 StartInterval + WatchPaths；interval 是周期兜底。
  services.git-sync.repositories.docs = {
    path = "${config.home.homeDirectory}/Desktop/docs";
    uri = "https://github.com/xbpk3t/docs.git";
    interval = 24 * 60 * 60;
  };
}
