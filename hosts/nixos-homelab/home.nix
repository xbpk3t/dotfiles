_: {
  modules = {
    infra = {
      basePackages.enable = true;
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

    desktop = {
      zed = {
        remote.enable = true;
      };
    };

    AI = {
      codex.enable = false;
      skills.enable = false;
    };

    ms = {
      k8s = {
        enable = true;
        core.enable = true;
        cluster.enable = true;
      };
    };

    devops.ssh = {
      enable = true;
    };

    langs = {
      lsp.enable = true;
    };

    xdg.enable = true;
  };
}
