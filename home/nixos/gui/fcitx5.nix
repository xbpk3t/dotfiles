{pkgs, ...}: {
  # Fcitx5 简化智能拼音输入法配置
  # 只保留核心功能：简体中文 + 英文 + 智能拼音
  # [fcitx5 settings](https://gist.github.com/ktpss95112/8c0b79a8f82058b89633a4fd1d3e9fa4)

  #  # 测试 fcitx5 是否运行
  #  fcitx5-remote
  #
  #  # 输出应该是：
  #  # 1 (中文模式) 或 2 (英文模式)
  #
  #  # 切换到中文模式
  #  fcitx5-remote -o
  #
  #  # 切换到英文模式
  #  fcitx5-remote -c

  #  # Fcitx5 日志
  #  journalctl --user -u fcitx5 -f
  #
  #  # 或查看系统日志
  #  tail -f ~/.local/share/fcitx5/crash.log
  #
  #  # 以调试模式启动 fcitx5
  #  fcitx5 -d --replace --verbose=debug

  # Fcitx5 配置文件 - 使用 home.file 直接写入
  home.file = {
    # Fcitx5 主配置文件
    ".config/fcitx5/config".text = ''
      # 全局配置
      [Hotkey]
      # 切换输入法快捷键：Ctrl+Space（中文/英文）
      TriggerKeys=Control+space
      # 枚举快捷键
      EnumerateWithTriggerKeys=True
      # 枚举时跳过第一个输入法
      EnumerateSkipFirst=False

      [Hotkey/TriggerKeys]
      0=Control+space

      [Behavior]
      # 共享输入状态：No (每个应用独立状态)
      ShareInputState=No
      # 预编辑模式
      PreeditEnabledByDefault=True
      # 显示输入法信息
      ShowInputMethodInformation=True
      # 默认页面大小
      DefaultPageSize=7
    '';

    # Fcitx5 输入法配置文件
    ".config/fcitx5/profile".text = ''
      [Groups/0]
      # 组名称
      Name=Default
      # 默认布局
      Default Layout=us
      # 默认输入法
      DefaultIM=pinyin

      [Groups/0/Items/0]
      # 英文键盘
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      # 智能拼音
      Name=pinyin
      Layout=

      [GroupOrder]
      0=Default
    '';

    # 拼音输入法配置
    ".config/fcitx5/conf/pinyin.conf".text = ''
      # 拼音引擎配置
      [Behavior]
      # 启用云拼音
      CloudPinyinEnabled=True
      # 云拼音候选词位置（3表示第3个位置）
      CloudPinyinIndex=3
      # 模糊拼音
      FuzzyPinyinEnabled=True
      # 模糊音配置 (z=zh, c=ch, s=sh, n=l, l=n)
      FuzzyPinyinPairs=z:zh;c:ch;s:sh;n:l;l:n
      # 仅启用简体字符集
      CharsetType=Simplified
      # 启用简拼
      IncompletePinyinEnabled=True
      # 显示完整拼音
      ShowCompletePinyin=True
      # 启用词频调整
      AdjustOrderByFrequency=True
      # 候选词数量
      PageSize=7
    '';

    ".config/fcitx5/conf/classicui.conf".text = ''
      [UI]
      Theme=mellow-vermilion
      # 字体
      Font=Noto Sans CJK SC 12
      # 可选：水平候选列表
      VerticalCandidateList=False
      # ... 其他 UI 设置
    '';
  };

  # 输入法系统配置
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      # 智能拼音输入引擎 (核心)
      fcitx5-chinese-addons
      # 配置工具
      fcitx5-configtool

      # https://github.com/sanweiya/fcitx5-mellow-themes
      fcitx5-mellow-themes

      # https://github.com/catppuccin/fcitx5
      catppuccin-fcitx5
    ];
  };

  # 环境变量
  home.sessionVariables = {
    # 输入法相关环境变量
    # GTK_IM_MODULE = "fcitx";
    # QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
