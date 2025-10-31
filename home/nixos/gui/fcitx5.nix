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
      0=Zenkaku_Hankaku
      1=Hangul
      2=Control+space
      [Hotkey/AltTriggerKeys]
      0=Shift_L
      1=Shift+Shift_R
      [Hotkey/EnumerateForwardKeys]
      0=Control+Shift+Shift_R
      1=Control+Shift+Shift_L
      [Hotkey/EnumerateGroupForwardKeys]
      0=Super+space
      [Hotkey/ActivateKeys]
      0=Hangul_Hanja
      [Hotkey/DeactivateKeys]
      0=Hangul_Romaja
      [Hotkey/PrevPage]
      0=Up
      [Hotkey/NextPage]
      0=Down
      [Hotkey/PrevCandidate]
      0=Shift+Tab
      [Hotkey/NextCandidate]
      0=Tab
      [Hotkey/TogglePreedit]
      0=Control+Alt+P
      # 禁用 Ctrl+Shift+F 切换繁简体
      [Hotkey/FullWidth]
      0=Shift+space
      # 禁用所有可能导致繁简切换的快捷键
      [Hotkey/SimplifiedTraditionalSwitch]
      # 删除或注释掉任何繁简切换快捷键
      [Behavior]
      # 共享输入状态：No (每个应用独立状态)
      ShareInputState=No
      # 预编辑模式
      PreeditEnabledByDefault=True
      # 显示输入法信息
      ShowInputMethodInformation=True
      # 显示输入法信息当切换焦点
      showInputMethodInformationWhenFocusIn=False
      # 显示紧凑输入法信息
      CompactInputMethodInformation=True
      # 显示第一个输入法信息
      ShowFirstInputMethodInformation=True
      # 默认页面大小
      DefaultPageSize=7
      # 是否默认激活
      ActiveByDefault=False
      # 覆盖 Xkb 选项
      OverrideXkbOption=False
      # 自定义 Xkb 选项
      CustomXkbOption=
      # 强制启用的插件
      EnabledAddons=
      # 强制禁用的插件 - 禁用可能影响繁简体的插件
      DisabledAddons=chttrans, traditionalchinese
      # 默认预加载输入法
      PreloadInputMethod=True
      # 枚举输入法后退
      EnumerateBackwardKeys=
      # 枚举输入法组后退
      EnumerateGroupBackwardKeys=
    '';

    # Fcitx5 输入法配置文件 - 更严格地限制输入法选项
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

    # 拼音输入法配置 - 强制简体
    ".config/fcitx5/conf/pinyin.conf".text = ''
      # 拼音引擎配置
      [Behavior]
      # 启用云拼音
      CloudPinyinEnabled=True
      # 云拼音候选词位置（1表示第1个位置，优化热词显示）
      CloudPinyinIndex=1
      # 云拼音后端选择（推荐百度）
      CloudPinyinBackend=Baidu
      # 模糊拼音
      FuzzyPinyinEnabled=True
      # 模糊音配置 (z=zh, c=ch, s=sh, n=l, l=n)
      FuzzyPinyinPairs=z:zh;c:ch;s:sh;n:l;l:n
      # 仅启用简体字符集 - 关键设置
      CharsetType=Simplified
      # 禁用繁简转换相关功能
      TraditionalChineseFallbackEnabled=False
      # 启用简拼
      IncompletePinyinEnabled=True
      # 显示完整拼音
      ShowCompletePinyin=True
      # 启用词频调整
      AdjustOrderByFrequency=True
      # 候选词数量
      PageSize=10
      # 确保首选项为简体中文
      PreferSimplifiedChinese=True
    '';

    # 禁用繁简转换插件配置
    ".config/fcitx5/conf/chttrans.conf".text = ''
      [General]
      # 禁用繁简转换功能
      Enabled=False
    '';

    # UI 配置
    #    ".config/fcitx5/conf/classicui.conf".text = ''
    #      [UI]
    #      # 主题
    #      Theme=stylix
    #      # 字体
    #      Font=Noto Sans CJK SC 12
    #      # 菜单字体
    #      MenuFont=Noto Sans CJK SC 12
    #      # 托盘字体
    #      TrayFont=Noto Sans CJK SC Bold 12
    #      # 垂直候选列表
    #      Vertical Candidate List=True
    #      # 使用每屏幕 DPI
    #      PerScreenDPI=True
    #      # 使用鼠标滚轮翻页
    #      WheelForPaging=True
    #      # 托盘标签轮廓颜色
    #      TrayOutlineColor=#000000
    #      # 托盘标签文本颜色
    #      TrayTextColor=#ffffff
    #      # 优先使用文本图标
    #      PreferTextIcon=False
    #      # 在图标中显示布局名称
    #      ShowLayoutNameInIcon=True
    #      # 使用输入法语言显示文本
    #      UseInputMethodLangaugeToDisplayText=True
    #    '';

    # 注音输入法配置
    #    ".config/fcitx5/conf/chewing.conf".text = ''
    #      # 选词键
    #      SelectionKey=1234567890
    #      # 每页候选词数量
    #      PageSize=10
    #      # 候选列表布局
    #      CandidateLayout=Vertical
    #      # 使用数字键盘作为选词键
    #      UseKeypadAsSelection=False
    #      # 正向添加短语
    #      AddPhraseForward=True
    #      # 反向选择短语
    #      ChoiceBackward=True
    #      # 自动移动光标
    #      AutoShiftCursor=True
    #      # 使用空格作为选词键
    #      SpaceAsSelection=False
    #      # 键盘布局
    #      Layout="Default Keyboard"
    #    '';

    # 全角/半角切换配置
    ".config/fcitx5/conf/fullwidth.conf".text = ''
      [Hotkey]
      0=Shift+space
    '';

    # 通知配置
    #    ".config/fcitx5/conf/notification.conf".text = ''
    #      [HiddenNotifications]
    #      0=enumerate-group
    #    '';

    # 标点符号配置
    ".config/fcitx5/conf/punctuation.conf".text = ''
      # 在字母或数字后使用半角标点
      HalfWidthPuncAfterLetterOrNumber=False


      # 成对输入标点（如引号）
      TypePairedPunctuationsTogether=False
      # 启用标点配置
      Enabled=True
      [Hotkey]
      0=Control+period
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
      # [2025-10-31] 不需要GUI来做fcitx5配置
      # fcitx5-configtool

      # 基于中文维基百科的拼音词典
      fcitx5-pinyin-zhwiki
      # https://github.com/sanweiya/fcitx5-mellow-themes
      # fcitx5-mellow-themes
      # https://github.com/catppuccin/fcitx5
      # catppuccin-fcitx5
    ];
  };

  # 环境变量
  home.sessionVariables = {
    # 输入法相关环境变量
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
