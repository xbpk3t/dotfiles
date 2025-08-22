{ ... }:

{
  # 保留部分 GUI 应用使用 Homebrew
  homebrew = {
    enable = true;
    taps = [
     "kilvn/homebrew-schedule"
    ];
    casks = [
      "alfred"
      "goland"
      "google-chrome"
      "hammerspoon"
      # "hyperconnect"
      "tencent-lemon"
      "wechat"
      "kilvn/homebrew-schedule/clashx-meta"
      "reqable"
      "orbstack"
    ];
    onActivation.cleanup = "zap"; # 只安装nix配置的pkg，除此之外全部移除
    onActivation.autoUpdate = true; # 每次rebuild时，自动升级brew
    onActivation.upgrade = true;
  };
}
