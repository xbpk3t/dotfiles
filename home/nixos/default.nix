{mylib, ...}: {
  imports = [../base] ++ mylib.scanPaths ./.;

  # 禁用指定工具的stylix配置
  stylix.targets = {
    rofi.enable = false;
    zed.enable = false;
    helix.enable = false;
    alacritty.enable = true;
    # 配置 Firefox profile names 以避免 stylix warning
    firefox.profileNames = ["default"];
  };
}
