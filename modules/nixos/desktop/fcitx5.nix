{pkgs, ...}: {
  # [2025-12-21] 注意之所以没有放到 nixos/base/i18n.nix 里，是因为fcitx5需要graphical支持。且desktop本身一定已经配置了input，并不需要minimal去配置input

  # 几点心得：
  # 1、可以看到，最后我把所有之前的配置都注释掉了，因为实际上全都是默认配置，那么为啥要写了？
  # 2、应该全部都用nix配置，而非之前的conf文件写法（用 home.file直接symlink）。这里需要注意的是并不需要很多人的 0, 1, 2 这种写法（或者 key."0" 这种写法），如果不写这些东西，直接写主key，默认就是0。
  # 3、与很多其他nix服务不同，修改fcitx5配置，并 nixos apply 之后，需要 fcitx5 -d --replace 让配置重新生效之后，再检查相应配置是否生效。才是完整的使用流程。

  # [fcitx5 settings](https://gist.github.com/ktpss95112/8c0b79a8f82058b89633a4fd1d3e9fa4)

  # https://github.com/Ev357/.dotfiles/blob/main/modules/fcitx5/settings.nix 我的配置基本上就是从这个复制过来的

  # https://github.com/kyehn/kudzu/blob/main/nixos/modules/fcitx5.nix
  # https://github.com/Sittymin/nixos_config/blob/main/system/config/locale.nix
  # https://github.com/chenlijun99/dotfiles/blob/master/src/nixos/users/common/lijun-base/fcitx5.nix 目前找到最全面的 fcitx5 的 nix 配置
  # https://github.com/ChUrl/flake-nixinator/blob/master/home/modules/fcitx/default.nix
  # https://github.com/yutkat/dotfiles/tree/main/.config/fcitx5/conf

  # https://mynixos.com/nixpkgs/options/i18n.inputMethod.fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;

      addons = with pkgs; [
        # 智能拼音输入引擎 (核心)
        qt6Packages.fcitx5-chinese-addons

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

      settings = {
        # profile 中的输入法组 (.config/fcitx5/profile)
        inputMethod = {
          GroupOrder = {
            "0" = "Default";
          };
          "Groups/0" = {
            # 组名称
            Name = "Default";
            # 默认布局
            "Default Layout" = "us";
            # 默认输入法
            DefaultIM = "pinyin";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = "";
          };
          "Groups/0/Items/1" = {
            Name = "pinyin";
            Layout = "";
          };
        };

        # 主配置 (.config/fcitx5/config)
        #        globalOptions = {
        # 热键设置
        #          Hotkey = {
        #            # 切换启用/禁用输入法
        #            TriggerKeys = "Ctrl+Space";
        #            # 控制枚举输入法组的组合键 (映射 [Hotkey/EnumerateGroupForwardKeys])
        #            EnumerateGroupForwardKeys = "Super+space";
        #            # 反复按切换键时进行轮换
        #            EnumerateWithTriggerKeys = "True";
        #            # 临时在当前和第一个输入法之间切换
        #            AltTriggerKeys = "Shift_L";
        #            # 向前切换输入法
        #            EnumerateForwardKeys = "Control+Shift+Shift_R";
        #            # 轮换输入法时跳过第一个输入法
        #            EnumerateSkipFirst = "False";
        #            # 激活输入法
        #            ActivateKeys = "";
        #            # 取消激活输入法
        #            DeactivateKeys = "";
        #            # 默认上一页
        #            PrevPage = "Up";
        #            # 默认下一页
        #            NextPage = "Down";
        #            # 默认跳转前一个候选词
        #            # PrevCandidate = "Shift+Tab";
        #            # 默认跳转下一个候选词
        #            # NextCandidate = "Tab";
        #            # 切换是否使用嵌入预编辑
        #            TogglePreedit = "Control+Alt+P";
        #          };

        #          # 触发输入法的多套快捷键 (映射 [Hotkey/TriggerKeys])
        #          "Hotkey/TriggerKeys" = {
        #            "0" = "Zenkaku_Hankaku";
        #            "1" = "Hangul";
        #            "2" = "Control+space";
        #          };
        #          # 备用触发键 (映射 [Hotkey/AltTriggerKeys])
        #          "Hotkey/AltTriggerKeys" = {
        #            "0" = "Shift_L";
        #            "1" = "Shift+Shift_R";
        #          };
        #          # 控制循环枚举输入法的组合键 (映射 [Hotkey/EnumerateForwardKeys])
        #          "Hotkey/EnumerateForwardKeys" = {
        #            "0" = "Control+Shift+Shift_R";
        #            "1" = "Control+Shift+Shift_L";
        #          };
        #          # 控制枚举输入法组的组合键 (映射 [Hotkey/EnumerateGroupForwardKeys])
        #          "Hotkey/EnumerateGroupForwardKeys" = {
        #            "0" = "Super+space";
        #          };
        #          # 激活输入法的快捷键 (映射 [Hotkey/ActivateKeys])
        #          "Hotkey/ActivateKeys" = {
        #            "0" = "Hangul_Hanja";
        #          };
        #          # 取消激活输入法的快捷键 (映射 [Hotkey/DeactivateKeys])
        #          "Hotkey/DeactivateKeys" = {
        #            "0" = "Hangul_Romaja";
        #          };
        #          # 候选页上一页 (映射 [Hotkey/PrevPage])
        #          "Hotkey/PrevPage" = {
        #            "0" = "Up";
        #          };
        #          # 候选页下一页 (映射 [Hotkey/NextPage])
        #          "Hotkey/NextPage" = {
        #            "0" = "Down";
        #          };
        #          # 候选项前一个 (映射 [Hotkey/PrevCandidate])
        #          "Hotkey/PrevCandidate" = {
        #            "0" = "Shift+Tab";
        #          };
        #          # 候选项后一个 (映射 [Hotkey/NextCandidate])
        #          "Hotkey/NextCandidate" = {
        #            "0" = "Tab";
        #          };
        #          # 快速切换预编辑模式 (映射 [Hotkey/TogglePreedit])
        #          "Hotkey/TogglePreedit" = {
        #            "0" = "Control+Alt+P";
        #          };
        #          # 保留全角/半角切换快捷键，避免被默认乱改 (映射 [Hotkey/FullWidth])
        #          "Hotkey/FullWidth" = {
        #            "0" = "Shift+space";
        #          };

        #          Behavior = {
        #            # 默认状态为激活
        #            ActiveByDefault = "False";
        #            # 重新聚焦时重置状态
        #            resetStateWhenFocusIn = "No";
        #            # 共享输入状态
        #            ShareInputState = "No";
        #            # 在程序中显示预编辑文本
        #            PreeditEnabledByDefault = "True";
        #            # 切换输入法时显示输入法信息
        #            ShowInputMethodInformation = "True";
        #            # 在焦点更改时显示输入法信息
        #            showInputMethodInformationWhenFocusIn = "False";
        #            # 显示紧凑的输入法信息
        #            CompactInputMethodInformation = "True";
        #            # 显示第一个输入法的信息
        #            ShowFirstInputMethodInformation = "True";
        #            # 默认页大小
        #            DefaultPageSize = "7";
        #            # 覆盖 Xkb 选项
        #            OverrideXkbOption = "False";
        #            # 自定义 Xkb 选项
        #            CustomXkbOption = "";
        #            # Force Enabled Addons
        #            EnabledAddons = "";
        #            # Force Disabled Addons
        #            DisabledAddons = "chttrans, traditionalchinese";
        #            # Preload input method to be used by default
        #            PreloadInputMethod = "True";
        #            # 允许在密码框中使用输入法
        #            AllowInputMethodForPassword = "False";
        #            # 输入密码时显示预编辑文本
        #            ShowPreeditForPassword = "False";
        #            # 保存用户数据的时间间隔（以分钟为单位）
        #            AutoSavePeriod = "30";
        #          };
        #        };

        # 各个插件的 ini 片段
        addons = {
          punctuation = {
            globalSection = {
              HalfWidthPuncAfterLetterOrNumber = "False";
              TypePairedPunctuationsTogether = "False";
              Enabled = "True";
            };
            sections.Hotkey."0" = "Control+period";
          };

          chttrans = {
            globalSection = {
              Enabled = "False";
            };
            # 很重要，用来移除默认的 Ctrl+Shift+F 这个用来切换简繁中文的快捷键（以避免不小心切换到繁体中文）
            sections.Hotkey."0" = "";
          };

          pinyin = {
            globalSection = {
              ShuangpinProfile = "Ziranma";
              ShowShuangpinMode = "True";
              PageSize = 7;
              SpellEnabled = "False";
              SymbolsEnabled = "False";
              ChaiziEnabled = "True";
              ExtBEnabled = "True";
              CloudPinyinEnabled = "True";
              CloudPinyinIndex = 1;
              CloudPinyinBackend = "Baidu";

              # 首个candidate会被替换为一个loading的icon，在得到真正结果前用来占位
              CloudPinyinAnimation = "False";
              KeepCloudPinyinPlaceHolder = "False";

              #              FuzzyPinyinEnabled = "True";
              #              FuzzyPinyinPairs = "z:zh;c:ch;s:sh;n:l;l:n";

              CharsetType = "Simplified";
              TraditionalChineseFallbackEnabled = "False";
              IncompletePinyinEnabled = "True";
              ShowCompletePinyin = "True";
              AdjustOrderByFrequency = "True";
              PreferSimplifiedChinese = "True";

              PreeditMode = "\"Composing pinyin\"";
              PreeditCursorPositionAtBeginning = "True";
              PinyinInPreedit = "False";
              Prediction = "False";
              PredictionSize = 10;
              SwitchInputMethodBehavior = "\"Commit current preedit\"";
              SecondCandidate = "";
              ThirdCandidate = "";
              UseKeypadAsSelection = "False";
              BackSpaceToUnselect = "True";
              "Number of sentence" = 2;
              LongWordLengthLimit = 4;
              VAsQuickphrase = "False";
              FirstRun = "False";
              QuickPhraseKey = "";
            };
            sections = {
              ForgetWord."0" = "Control+7";
              PrevPage = {
                "0" = "minus";
                "1" = "Up";
                "2" = "KP_Up";
                "3" = "Page_Up";
              };
              NextPage = {
                "0" = "equal";
                "1" = "Down";
                "2" = "KP_Down";
                "3" = "Next";
              };
              PrevCandidate."0" = "Shift+Tab";
              NextCandidate."0" = "Tab";
              ChooseCharFromPhrase = {
                "0" = "bracketleft";
                "1" = "bracketright";
              };
              FilterByStroke."0" = "grave";
              "QuickPhrase trigger" = {
                "0" = "www.";
                "1" = "ftp.";
                "2" = "http:";
                "3" = "mail.";
                "4" = "bbs.";
                "5" = "forum.";
                "6" = "https:";
                "7" = "ftp:";
                "8" = "telnet:";
                "9" = "mailto:";
              };
              #              Fuzzy = {
              #                VE_UE = "True";
              #                NG_GN = "True";
              #                Inner = "True";
              #                InnerShort = "True";
              #                PartialFinal = "True";
              #                PartialSp = "False";
              #                V_U = "True";
              #                AN_ANG = "True";
              #                EN_ENG = "True";
              #                IAN_IANG = "True";
              #                IN_ING = "True";
              #                U_OU = "True";
              #                UAN_UANG = "True";
              #                C_CH = "True";
              #                F_H = "True";
              #                L_N = "True";
              #                S_SH = "True";
              #                Z_ZH = "True";
              #                Correction = "None";
              #              };
            };
          };

          # 拼音引擎设置
          #          pinyin = {
          #            Behavior = {
          #              CloudPinyinEnabled = true;
          #              CloudPinyinIndex = 1;
          #              CloudPinyinBackend = "Baidu";
          #              FuzzyPinyinEnabled = true;
          #              FuzzyPinyinPairs = "z:zh;c:ch;s:sh;n:l;l:n";
          #              CharsetType = "Simplified";
          #              TraditionalChineseFallbackEnabled = false;
          #              IncompletePinyinEnabled = true;
          #              ShowCompletePinyin = true;
          #              AdjustOrderByFrequency = true;
          #              PageSize = 10;
          #              PreferSimplifiedChinese = true;
          #            };
          #          };

          # 繁简插件完全禁用，防止调出快捷键
          #          chttrans = {
          #            General = {
          #              Enabled = false;
          #            };
          #          };

          # 标点配置，只有数字/字母后使用半角的逻辑交给 data/punc 统一控制
          #          punctuation = {
          #            HalfWidthPuncAfterLetterOrNumber = false;
          #            TypePairedPunctuationsTogether = false;
          #            Enabled = true;
          #            Hotkey = {
          #              "0" = "Control+period";
          #            };
          #          };
        };
      };
    };
  };

  # 输入法与 Wayland 环境（仅 GNOME 会话下生效，避免污染其他会话）
  environment.sessionVariables = {
    # 输入法相关env
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    SDL_IM_MODULE = "fcitx";
  };
}
