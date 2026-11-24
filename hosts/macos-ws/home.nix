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
      apm.enable = true;
      ocr.enable = true;
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

  # docs: Mutagen 只同步工作区，.git 由 --ignore-vcs 排除；
  # 其余 ignore 直接读 docs repo 里 tracked 的 .gitignore（含 docs/、wiki/ 下的嵌套文件）。
  # Mac 是唯一 git owner；agt 只接收文件，不跑 git。
  modules.devops.mutagen = {
    enable = true;
    syncs.docs = {
      alpha = "${config.home.homeDirectory}/Desktop/docs";
      beta = "nixos-vps-agt:/home/luck/Desktop/docs";
      gitignore = true;
    };
  };
}
