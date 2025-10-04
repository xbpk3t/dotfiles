{...}: {
  # https://mynixos.com/home-manager/options/programs.wezterm
  programs.wezterm = {
    enable = true;

    enableBashIntegration = true;
    # enableZshIntegration = true;

    colorSchemes = {};

    extraConfig = ''
      local wezterm = require('wezterm')

      return {
        -- 基础配置
        color_scheme = 'Catppuccin Mocha',
        font_size = 13,

        -- 字体配置
        font = wezterm.font_with_fallback({
          'JetBrains Mono',
          'LXGW WenKai Screen',
          'Noto Color Emoji'
        }),

        -- 标签栏
        enable_tab_bar = true,
        hide_tab_bar_if_only_one_tab = true,

        -- 滚动历史
        scrollback_lines = 5000,

        -- 基础快捷键
        keys = {
          -- 字体大小
          { key = '+', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
          { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
          { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },

          -- 复制粘贴
          { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo('Clipboard') },
          { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom('Clipboard') },
        },
      }
    '';
  };
}
