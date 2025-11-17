{pkgs, ...}: {
  home.packages = with pkgs; [
    cliphist

    # https://mynixos.com/nixpkgs/package/clipboard-jh
    # https://github.com/Slackadays/Clipboard
    # Support for search item, but not support fetch latest N items.
    # https://github.com/Slackadays/Clipboard/releases/tag/0.10.0
    # Not support wayland by now.
    # clipboard-jh
  ];

  services.cliphist = {
    enable = true;
    package = pkgs.cliphist;
    allowImages = true;
  };
}
