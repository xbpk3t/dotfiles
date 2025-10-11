_: {
  homebrew = {
    enable = true;
    casks = [
      "alfred"
      "hammerspoon"

      "goland"
      "google-chrome"

      "tencent-lemon"

      #      "orbstack"
      #      "reqable"

      #      "wechat"
      #      "wireshark-app"
    ];
    # 开启这个配置，以及autoUpdate。完全由nix管理brew
    greedyCasks = true;

    onActivation = {
      cleanup = "zap"; # 只安装nix配置的pkg，除此之外全部移除
      autoUpdate = false; # 每次rebuild时，自动升级brew
      upgrade = false;
    };
  };
}
