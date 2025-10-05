{pkgs, ...}: {
  programs = {
    bash = {
      enable = true;
    };

    zsh = {
      enable = true;
      enableCompletion = true;

      autosuggestions = {
        enable = true;
        async = true;
        highlightStyle = "fg=cyans";
        extraConfig = {
          ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
          ZSH_AUTOSUGGEST_USE_ASYNC = "y";
        };
      };

      syntaxHighlighting = {
        enable = true;
        styles = {
          "alias" = "fg=magenta,bold";
        };
      };

      shellAliases = {
        # 目录导航
        # zsh 支持 "-" 作为别名，直接使用
        "-" = "cd -";
        "..." = "../..";
        "...." = "../../..";
        "....." = "../../../..";
        "......" = "../../../../..";
        # zsh 支持数字历史导航
        "-1" = "cd -1";
        "-2" = "cd -2";
        "-3" = "cd -3";
        "-4" = "cd -4";
        "-5" = "cd -5";

        # 权限和基础命令
        "_" = "sudo ";
        "c" = "clear";

        # 现代工具替代
        "cat" = "bat";
        "find" = "fd --hidden"; # 使用 fd 替代 find，显示隐藏文件
        "grep" = "rg";

        # 文件操作
        ll = "eza -la";
        la = "eza -a";
        lls = "eza -la --sort=size --reverse --total-size";
        "md" = "mkdir -p";
        "rd" = "rmdir";

        # 编辑器
        "vim" = "LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 nvim";
      };

      # zsh 的 shell 选项设置（性能优化）
      # 性能优化配置
      enableGlobalCompInit = true;

      # 历史管理优化
      histFile = "$HOME/.zsh_history";

      # 终端和颜色集成
      vteIntegration = true;
      enableLsColors = true;

      # 结构化 zsh 选项配置
      setOptions = [
        # 历史相关选项
        "append_history" # 追加历史而不是覆盖
        "hist_verify" # 历史展开时先验证
        "hist_ignore_dups" # 忽略重复命令
        "hist_ignore_space" # 忽略以空格开头的命令
        "hist_no_store" # 不存储 history 命令本身

        # 性能和便利性选项
        "auto_cd" # 启用自动 cd 功能
        "correct" # 自动纠正命令拼写错误
        "cdable_vars" # 允许 cd 到变量名
        "check_jobs" # 退出时检查后台任务
        # "checkwinsize" # 检查窗口大小变化 zsh没有该项，bash的专有option
        "no_case_glob" # 处理忽略大小写的通配符
        "extended_glob" # 启用扩展通配符
        "nomatch" # 如果通配符没有匹配，报错
        "notify" # 立即报告后台任务状态
        "pushd_ignore_dups" # 忽略 pushd 重复目录
        "pushd_silent" # 静默 pushd
        "auto_pushd" # 自动 pushd
      ];
    };
  };

  # 添加用户可用的 shell 到 /etc/shells
  environment.shells = with pkgs; [
    bashInteractive
    zsh
    nushell
  ];

  # 设置系统默认用户 shell
  # 这会影响新创建的用户和通过 users.defaultUserShell 设置的用户
  users.defaultUserShell = pkgs.zsh;

  # ===== Shell 相关环境变量 =====
  # 可以在这里添加 shell 相关的全局环境变量
  # environment.variables = {
  #   SHELL = "${pkgs.zsh}/bin/zsh";
  # };
}
