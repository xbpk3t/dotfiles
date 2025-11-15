_: {
  # https://mynixos.com/nixpkgs/package/aerospace
  # https://mynixos.com/nix-darwin/options/services.aerospace

  # jankyborders macos专用，用来高亮当前window和 aerospace 等window管理器集成
  # https://mynixos.com/nixpkgs/package/jankyborders
  # https://mynixos.com/nix-darwin/options/services.jankyborders
  services.aerospace = {
    enable = true;
  };
}
