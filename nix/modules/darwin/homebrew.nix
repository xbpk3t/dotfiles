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
      "cursor"
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
    onActivation = {
      cleanup = "zap"; # 只安装nix配置的pkg，除此之外全部移除
      autoUpdate = true; # 每次rebuild时，自动升级brew
      upgrade = true;
    };
  };
}
