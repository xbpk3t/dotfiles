_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    devops = {
      tmux.enable = false;
      ssh = {
        enable = true;
        hosts = {
          # github.enable = true;
          hk-hdy.enable = true;
          LA.enable = true;
          homelab.enable = true;
        };
      };
    };

    desktop = {
      stylix.enable = true;

      ghostty.enable = false;
      cmux.enable = true;

      zed.enable = true;
    };

    AI = {
      cc-connect.enable = true;
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
