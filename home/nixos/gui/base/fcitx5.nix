{pkgs, ...}: {
  # Fcitx5 简化智能拼音输入法配置
  # 只保留核心功能：简体中文 + 英文 + 智能拼音

  xdg.configFile = {
    # Fcitx5 主配置文件
    "fcitx5/config" = {
      text = ''
        # 全局配置
        [Hotkey]
        # 切换输入法快捷键：Ctrl+Space
        TriggerKey=CTRL_SPACE
        # 切换输入法引擎快捷键：Alt+Shift
        IMSwitchKey=ALT_SHIFT
        # 枚举快捷键
        EnumerateWithTriggerKeys=True
        # 枚举时第一个输入法激活
        EnumerateSkipFirst=False

        [Behavior]
        # 共享输入状态
        ShareInputState=No
        # 预编辑模式
        PreeditInApplication=Yes
        # 显示输入法图标
        ShowInputMethodIcon=Yes
        # 显示语言栏
        ShowLanguageBar=No
        # 覆盖 XKB 设置
        OverrideXkbOption=Yes
        # 自定义 XKB 选项
        CustomXkbOption=

        [Output]
        # 默认输出简体中文
        HalfPuncAfterNumber=True
        # 英文模式下使用半角标点
        HalfPuncInFirst=True
      '';
      force = true;
    };

    # Fcitx5 输入法配置文件
    "fcitx5/profile" = {
      text = ''
        [Groups/0]
        # 组名称
        Name=Default
        # 默认布局
        Default Layout=us
        # 默认输入法
        DefaultIM=pinyin

        [Groups/0/Items/0]
        # 名称
        Name=keyboard-us
        # 布局
        Layout=

        [Groups/0/Items/1]
        # 名称
        Name=pinyin
        # 布局
        Layout=

        [GroupOrder]
        0=Default
      '';
      force = true;
    };

    # 拼音输入法配置
    "fcitx5/conf/pinyin.conf" = {
      text = ''
        # 拼音引擎配置
        [Engine/Pinyin]
        # 启用云拼音
        CloudPinyinEnabled=True
        # 云拼音候选词数量
        # 如果设置为1，则是热词优先级更高。所以设置为3。
        CloudPinyinIndex=3
        # 启用模糊音
        FuzzyPinyinEnabled=True
        # 模糊音配置 (z=zh, c=ch, s=sh, n=l, l=n, f=h, h=f)
        FuzzyPinyinPairs=z:zh;c:ch;s:sh;n:l;l:n;f:h;h:f
        # 仅启用简体字符集
        CharsetType=Simplified
        # 启用简拼
        IncompletePinyinEnabled=True
        # 不启用双拼
        ShuangpinEnabled=False
        # 显示完整拼音
        ShowCompletePinyin=True
        # 显示拼音符号
        ShowPinyinInAnnotation=True
        # 启用词频调整
        AdjustOrderByFrequency=True
        # 启用长词优先
        LongWordPriority=True
        # 候选词数量
        CandidatePageSize=7
        # 记忆用户选择
        MemoryUserWord=True
        # 启用快速短语
        QuickPhraseEnabled=True
        # 启用符号输入
        SymbolEnabled=True
        # 强制简体中文输出
        SimplifiedChineseOutput=True
        # 完全禁用繁体字转换
        TraditionalChineseOutput=False
        # 禁用简繁转换快捷键
        DisableSimplifiedToTraditional=True
      '';
      force = true;
    };

    # [fcitx5 社区主题包 · fcitx/fcitx5 · Discussion #382](https://github.com/fcitx/fcitx5/discussions/382)
    # 界面主题配置
    "fcitx5/conf/classicui.conf" = {
      text = ''
        # 经典界面配置
        [Theme]
        # 主题名称 (可用: Material-Color-deepPurple, Material-Color-blue, Material-Color-pink 等)
        Theme=Material-Color-deepPurple
        # 垂直候选列表
        VerticalCandidateList=False
        # 垂直预编辑文本
        VerticalPreeditText=True
        # 圆角
        RoundCorner=5
        # 边距
        Margin=4
        # 字体
        Font="Noto Sans CJK SC 13"
        # 高亮候选词颜色 (Material-Color 绿色)
        HighlightColor=32 201 151
        # 高亮背景颜色
        HighlightBackgroundColor=49 49 49
        # 文本颜色
        TextColor=255 255 255
        # 背景颜色
        BackgroundColor=49 49 49
        # 边框颜色
        BorderColor=255 255 255
        # 启用动画
        UseAnimation=True
        # 启用阴影
        UseShadow=True
      '';
      force = true;
    };

    # 云拼音配置
    "fcitx5/conf/cloudpinyin.conf" = {
      text = ''
        # 云拼音配置
        [CloudPinyin]
        # 启用云拼音
        Enabled=True
        # 云拼音后端 (baidu, google, custom)
        Backend=Baidu
        # 超时时间 (毫秒)
        Timeout=500
        # 最小查询长度
        MinimumLength=2
        # 最大查询长度
        MaximumLength=10
        # 缓存大小
        CacheSize=1000
        # 缓存过期时间 (小时)
        CacheExpire=24
      '';
      force = true;
    };

    # 简化标点符号配置
    "fcitx5/conf/punctuation.conf" = {
      text = ''
        # 基础标点符号映射 (仅常用)
        [Punc]
        ,=，
        .=。
        ;=；
        :=：
        ?=？
        !=！
        $=￥
        %=%
        &=&
        *=×
        -=-
        +=+
      '';
      force = true;
    };
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
      # Material-Color 主题 (包含10个颜色变体)
      fcitx5-material-color
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
