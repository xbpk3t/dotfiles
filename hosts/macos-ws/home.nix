{...}: {
  modules.ssh = {
    enable = true;
    hosts = {
      github.enable = true;
      vps.enable = true;
      hk.enable = true;
    };
  };

  modules.desktop = {
    alacritty.enable = false;
    ghostty.enable = true;

    vscode.enable = true;
  };
}
