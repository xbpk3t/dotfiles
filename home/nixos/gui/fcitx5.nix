{pkgs, ...}: {
  # Fcitx5 简化智能拼音输入法配置
  # 只保留核心功能：简体中文 + 英文 + 智能拼音

  # Fcitx5 配置文件 - 使用 home.file 直接写入
  home.file = {
    # Fcitx5 主配置文件
    ".config/fcitx5/config".text = ''
      # 全局配置
      [Hotkey]
      # 切换输入法快捷键：Ctrl+Space
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
