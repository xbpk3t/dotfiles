{pkgs, ...}: {
  programs = {
    nushell = {
      enable = true;

      # 环境变量配置
      environmentVariables = {
        # 编辑器配置
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      # Nushell 核心设置
      settings = {
        # 关闭欢迎信息
        show_banner = false;

        # 历史配置
        history = {
          file_size = 1 * 1024 * 1024; # 1MB
          max_size = 100000;
          sync_on_enter = true;
          file_format = "sqlite";
        };

        # 完成配置
        completions = {
          external = {
            enable = true;
            max_results = 100;
            completer = {
              # 使用外部完成器
              case_sensitive = false;
            };
          };
        };

        # 错误显示
        error_style = "fancy";
        display_errors = {
          exit_code = true;
        };

        # 表格显示
        table = {
          mode = "rounded"; # rounded,basic,compact,compact_double,light,thin
          index_mode = "always"; # always,never,auto
          trim = {
            methodology = "truncating"; # wrapping,truncating
            max_length = 80;
          };
        };

        # 文件大小显示
        filesize = {
          metric = true; # 使用公制 (KB, MB) 而不是二进制 (KiB, MiB)
          format = "auto"; # auto,b,kb,kib,mb,mib,gb,gib,tb,tib,pb,pib,eb,eib,zb,zib
        };

        # 钩子配置
        hooks = {
          pre_execution = "";
          pre_prompt = "";
        };
      };

      plugins = with pkgs.nushellPlugins; [
        # 格式支持插件
        formats
        # 可以添加更多插件：
        # inc
        # query
        # gstat
      ];
    };
  };
}
