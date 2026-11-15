_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
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
      k8s.enable = true;
    };

    devops.ssh = {
      enable = true;
    };

    langs = {
      lsp.enable = true;
    };
  };
}
