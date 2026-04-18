{...}: {
  modules.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
      homelab.enable = true;
    };
  };

  modules.desktop = {
    alacritty.enable = false;
    ghostty.enable = false;
    kitty.enable = false;

    zed.enable = true;
    vscode.enable = false;
  };

  modules.AI = {
    codex.enable = true;
    claude.enable = true;
    skills.enable = true;
    opencode.enable = true;
  };

  modules.langs = {
    lsp.enable = true;
  };

  modules.ms = {
    colima.enable = true;
  };
}
