{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.accounts.neomutt;
in {
  options.accounts.neomutt = {
    enable = lib.mkEnableOption "Enable Neomutt";
  };

  config = mkIf cfg.enable {
    accounts.email = {
      maildirBasePath = "Mail";
    };

    accounts.email.accounts = {
      gmail = {
        primary = true;
        address = "jeffcottlu@gmail.com";
        flavor = "gmail.com";
        realName = "jeffcott";
        passwordCommand = "echo ''";
        # 启用 GPG 加密和签名
        gpg = {
          encryptByDefault = true;
          signByDefault = true;
          key = "46E96F6FF44F3D74";
        };
        mbsync = {
          enable = true;
          # 更全面的 mbsync 同步设置，包括创建、删除和清空操作
          create = "both";
          remove = "both";
          expunge = "both";
          patterns = ["*"];
        };
        #      imapnotify = {
        #        enable = true;
        #        boxes = [ "Inbox" ];
        #        onNotify = "${lib.getExe config.my.services.mbsync.package} -a";
        #        onNotifyPost =
        #          if stdenv.hostPlatform.isLinux then
        #            "${lib.getExe pkgs.libnotify} 'New mail arrived'"
        #          else
        #            ''osascript -e "display notification \"New mail arrived\" with title \"email\""'';
        #      };

        notmuch.enable = true;
        neomutt.enable = true;
        # to sync with GMail's trash, I need to add the label like "+[Gmail]/ゴミ箱"
        # but labels with Japanese characters are not supported by neomutt
        # so I set the display language to English(US) in GMail settings
        folders = {
          inbox = "Inbox";
          sent = "\[Gmail\]/Sent\\ Mail";
          trash = "\[Gmail\]/Trash";
          drafts = "\[Gmail\]/Drafts";
        };
      };
    };

    programs.mbsync.enable = true;
    services.mbsync.enable = true;

    services.imapnotify.enable = true;

    programs.neomutt = {
      enable = true;
      sidebar = {
        enable = true;
      };
      sort = "reverse-last-date-received";
      vimKeys = true;
      settings = {
        # Display format for email timestamps:
        # - Today's emails: time only
        # - This year's emails: month/day/weekday/time
        # - Previous years: year/month/day/time
        # https://neomutt.org/feature/cond-date
        index_format = "'%4C %Z %<[y?%<[d?%[           %R]&%[%m/%d (%a) %R]>&%[%Y/%m/%d %R]> %-15.15L (%?l?%4l&%4c?) %s'";
      };
      extraConfig = ''
        # 启用邮件检查统计以提高性能
        set mail_check_stats
        # 启用 flowed text 格式支持
        set text_flowed
        # 设置文本重新换行宽度
        set reflow_wrap=140
        # 显示多部分/替代邮件的信息
        set show_multipart_alternative=info
        # 设置默认 PGP 密钥
        set pgp_default_key=46E96F6FF44F3D74
        # 禁用按键等待提示
        unset wait_key
        # 取消设置之前的所有邮箱
        unmailboxes *

        # 定义邮箱列表
        mailboxes +Inbox +Sent +Drafts +Spam +Trash +Archive '+Learn as Ham' '+Learn as Spam'

        # 多部分/替代滥用者列表处理
        # 针对那些在纯文本部分声明"你的邮件客户端不支持HTML邮件"的发送者...
        # 为非滥用者设置备选顺序
        message-hook '!%f alternative_abusers' "unalternative_order *; alternative_order text/plain text/html"
        # 为滥用者设置备选顺序
        message-hook '%f alternative_abusers' "unalternative_order *; alternative_order text/html text/plain"

        # 保留之前的外观
        color normal white black

        # URL 处理配置
        # 使用 urlview 提取和打开邮件中的链接
        # 在索引和页面视图中按 'u' 键调用 urlview
        macro index,pager u "<pipe-message>urlview<enter>" "Call urlview to extract URLs out of a message"

        # 设置默认浏览器（使用 XDG 配置）
        set browser = "xdg-open"

        set pager_index_lines=10
      '';
    };

    #  programs.neomutt.enableHtmlView = true;

    #  sops.secrets.gmail-app-password = {
    #    sopsFile = ./secrets.yaml;
    #  };
  };
}
