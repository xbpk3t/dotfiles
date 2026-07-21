_: {
  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    devops = {
      ssh = {
        enable = true;
        hosts = {
          # github.enable = true;
          hk-hdy.enable = true;
          LA.enable = true;
          homelab.enable = true;
        };
      };
      # Agent mux (orchestration / detach / wait). Package + config.toml via herdr.nix.
      # Trial: parallel with cmux; Claude SessionStart hook is in modules.AI.claude (HM),
      # not `herdr integration install`. Bump llm-agents to upgrade herdr version.
      herdr.enable = true;
    };

    desktop = {
      stylix.enable = true;

      # Host plan during herdr trial: cmux remains daily Terminal/cockpit.
      # Ghostty wide window was the preferred herdr host in eval — flip when ready;
      # do not force herdr into GoLand narrow terminal.
      ghostty.enable = true;
      cmux.enable = false;

      zed.enable = true;
    };

    AI = {
      cc-connect.enable = true;
      codex.enable = false;
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
