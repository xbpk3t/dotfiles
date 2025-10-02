{pkgs, ...}: {
  xdg.configFile = {
    # 内联 Fcitx5 配置文件，避免维护单独的 profile 文件
    "fcitx5/profile" = {
      text = ''
        [Groups/0]
        # Group Name
        Name=Default
        # Layout
        Default Layout=us
        # Default Input Method
        DefaultIM=rime

        [Groups/0/Items/0]
        # Name
        Name=keyboard-us
        # Layout
        Layout=

        [Groups/0/Items/1]
        # Name
        Name=rime
        # Layout
        Layout=

        [GroupOrder]
        0=Default
      '';
      # every time fcitx5 switch input method, it will modify ~/.config/fcitx5/profile,
      # so we need to force replace it in every rebuild to avoid file conflict.
      force = true;
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      # for flypy chinese input method
      fcitx5-rime
      # needed enable rime using configtool after installed
      fcitx5-configtool
      # fcitx5-chinese-addons # we use rime instead
      # fcitx5-mozc    # japanese input method
      fcitx5-gtk # gtk im module
    ];
  };
}
