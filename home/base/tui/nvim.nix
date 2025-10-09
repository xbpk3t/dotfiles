{...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    # 基本设置 (简洁版)
    opts = {
      number = true; # 显示行号
      cursorline = true; # 高亮当前行
      expandtab = true; # Tab转空格
      tabstop = 2; # Tab宽度
      shiftwidth = 2; # 缩进宽度
      ignorecase = true; # 搜索忽略大小写
      smartcase = true; # 智能大小写搜索
    };

    # 推荐的插件（精选5-6个）
    plugins = {
      # 必需：图标支持
      web-devicons.enable = true;

      # 推荐：状态栏
      lualine.enable = true;

      # 推荐：语法高亮
      treesitter.enable = true;

      # 推荐：LSP支持
      lsp.enable = true;
      lsp.servers = {
        nil_ls.enable = true; # Nix
        pyright.enable = true; # Python
        ts_ls.enable = true; # TypeScript
      };

      # 推荐：自动补全
      cmp.enable = true;
    };
  };
}
