{ ... }:
{
  modules.infra = {
    nh.enable = true;
    networking.enable = true;
  };

  modules.devops.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
      homelab.enable = true;
    };
  };

  modules.desktop = {
    stylix.enable = true;

    alacritty.enable = false;
    ghostty.enable = false;
    kitty.enable = false;
    cmux.enable = true;

    zed.enable = true;
    vscode.enable = false;
  };

  modules.AI = {
    codex.enable = true;
    claude.enable = true;
    skills.enable = true;
    pi-agent.enable = true;
    mcp.isDesktop = true;
  };

  modules.langs = {
    lsp.enable = true;
  };

  modules.ms = {
    colima.enable = true;
  };
}
