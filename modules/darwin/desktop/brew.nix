{
  inputs,
  userMeta,
  ...
}:
let
  inherit (userMeta) username;
in
{
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

    taps = [
    ];

    brews = [
      "fetch"
      "mole"
      "dagu"

      "vshulcz/tap/deja-vu"

      "vjeantet/tap/alerter"
      "mq"
    ];

    # 以下casks根据重要性排序
    casks = [
      "alfred"
      "hammerspoon"

      # "goland"
      "zed"

      "wechat"
      # "wechatwork"
      # "wetype"

      #"tailscale-app"

      # [2026-01-17] 在mac上我选择用chrome，而非firefox。因为
      "google-chrome"

      "ghostty"

      # "firefox"

      # [2026-03-28] 用不到了。对我来说 raycast核心功能就是 todoist，直接用web端了。另外raycast需要常驻内存200MB左右（包体本身占用内存150MB, 还有个座位 extension的node进程，50MB）
      # "raycast"

      "reqable"
      # "wireshark-app"
      # "rustdesk"
      # "orbstack"
      # "jetbrains-toolbox"
      # "visual-studio-code"
      # "tencent-lemon"
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

    goPackages = [
      # https://github.com/cage1016/ak
      # 说明：goPackages 里不要带 `@latest`。nix-homebrew 会自动在 go install 后拼
      # 一个版本后缀，若这里写 `@latest` 会拼成 `ak@latest@latest` 导致
      # `unknown revision latest@latest` 安装失败（实测报错）。
      "github.com/cage1016/ak"

      "go.uber.org/mock/mockgen"

      # https://github.com/ChimeraCoder/gojson
      # "github.com/ChimeraCoder/gojson/gojson"
    ];

  };
}
