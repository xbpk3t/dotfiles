{...}: {
  modules.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-claw.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
      homelab.enable = true;
    };
  };

  modules.desktop = {
    alacritty.enable = false;
    ghostty.enable = true;

    zed.enable = true;
    vscode.enable = false;
  };

  modules.AI = {
    codex.enable = true;
    opencode.enable = true;
  };

  modules.tui = {
    # terminal 直接使用 helix（而非nvim）
    nvim.enable = false;
  };

  modules.langs = {
    lsp.enable = true;
  };
}
