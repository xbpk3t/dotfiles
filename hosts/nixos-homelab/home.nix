_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    extra = {
      zed-remote.enable = true;
    };

    AI = {
      codex.enable = false;
      skills.enable = false;
    };

    devops.ssh = {
      enable = true;
      hosts = {
        # github.enable = true;
        hk-hdy.enable = true;
        LA.enable = true;
      };
    };

    langs = {
      lsp.enable = true;
    };
  };
}
