{
  inputs,
  userMeta,
  ...
}: let
  username = userMeta.username;
in {
  # 我们常说（对Nix来说） Docker是 escape hatch，其实在Nix里，brew也是 escape hatch
  # 我们可以把

  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    # Apple Silicon 常需 Rosetta 装 x86 cask
    # enableRosetta = pkgs.stdenv.isAarch64;
    enableRosetta = false;
    user = username;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    brews = [
      # https://github.com/gruntwork-io/fetch
      "fetch"

      # https://github.com/tw93/Mole
      "mole"
    ];

    # 以下casks根据重要性排序
    casks = [
      "alfred"
      "hammerspoon"

      "goland"

      "wechat"

      "ghostty"

      "tailscale-app"

      # [2026-01-17] 在mac上我选择用chrome，而非firefox。因为
      "google-chrome"

      # "firefox"

      # [2026-03-28] 用不到了。对我来说 raycast核心功能就是 todoist，直接用web端了。另外raycast需要常驻内存200MB左右（包体本身占用内存150MB, 还有个座位 extension的node进程，50MB）
      # "raycast"

      # "reqable"
      # "wireshark-app"
      # "rustdesk"
      # "orbstack"
      # "jetbrains-toolbox"
      # "visual-studio-code"
      # "tencent-lemon"

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
      autoUpdate = false;
      upgrade = false;
    };
  };
}
