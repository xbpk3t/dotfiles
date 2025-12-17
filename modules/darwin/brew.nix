{
  inputs,
  myvars,
  ...
}: {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    # Apple Silicon 常需 Rosetta 装 x86 cask
    # enableRosetta = pkgs.stdenv.isAarch64;
    enableRosetta = false;
    user = myvars.username;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    brews = [
      # https://github.com/gruntwork-io/fetch
      "fetch"
    ];

    # 以下casks根据重要性排序
    casks = [
      "alfred"
      "hammerspoon"
      "goland"
      "tencent-lemon"
      "wechat"
      "firefox"

      "ghostty"

      # "reqable"
      # "wireshark-app"
      # "google-chrome"
      # "rustdesk"
      # "orbstack"

      # https://github.com/insanum/gcalcli
      # https://formulae.brew.sh/formula/gcalcli
      # https://github.com/ajrosen/icalPal
    ];
    # 开启这个配置，以及autoUpdate。完全由nix管理brew
    greedyCasks = true;

    onActivation = {
      # 只安装nix配置的pkg，除此之外全部移除
      cleanup = "zap";
      # 每次rebuild时，自动升级brew
      autoUpdate = true;
      upgrade = true;
    };
  };
}
