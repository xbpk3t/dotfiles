_: {
  # 保留部分 GUI 应用使用 Homebrew
  homebrew = {
    enable = true;
    taps = [
      "kilvn/homebrew-schedule"
    ];
    brews = [
      # "cloudflare-wrangler"
    ];
    casks = [
      "alfred"
      "kilvn/homebrew-schedule/clashx-meta"
      "goland"
      "google-chrome"
      "hammerspoon"
      "orbstack"
      "reqable"
      "tencent-lemon"
      "wechat"
      "wireshark-app"
    ];
    # PLAN 目前orbstack 需要sonoma才能install，所以暂时注释。换MBP之后，开启这个配置，以及autoUpdate。完全由nix管理brew
    # greedyCasks = true;

    onActivation = {
      cleanup = "zap"; # 只安装nix配置的pkg，除此之外全部移除
      autoUpdate = false; # 每次rebuild时，自动升级brew
      upgrade = false;
    };
  };
}
