{...}: {
  modules.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-claw.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
    };
  };

  modules.desktop = {
    alacritty.enable = false;
    ghostty.enable = true;

    vscode.enable = false;
  };

  modules.AI = {
    codex.enable = true;
  };
}
