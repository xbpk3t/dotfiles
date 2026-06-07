_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    devops.ssh = {
      enable = true;
      hosts = {
        # github.enable = true;
        hk-hdy.enable = true;
        LA.enable = true;
        homelab.enable = true;
      };
    };

    desktop = {
      stylix.enable = true;

      alacritty.enable = false;
      ghostty.enable = false;
      kitty.enable = false;
      cmux.enable = true;

      zed.enable = true;
      vscode.enable = false;
    };

    AI = {
      codex.enable = true;
      claude.enable = true;
      skills.enable = true;
      pi-agent.enable = true;
      mcp.isDesktop = true;
    };

    langs = {
      lsp.enable = true;
    };

    ms = {
      colima.enable = true;
    };
  };
}
