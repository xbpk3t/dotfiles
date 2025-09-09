{ ... }:

{
  programs.starship = {
    enable = true;

    # 使用提供的 starship.toml 配置
    settings = {
      # Get editor completions based on the config schema
      "$schema" = "https://starship.rs/config-schema.json";

      right_format = "$cmd_duration$env_var";

      # Inserts a blank line between shell prompts
      add_newline = true;

      # Replace the '❯' symbol in the prompt with '➜'
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # Disable the package module, hiding it from the prompt completely
      package = {
        disabled = true;
      };

      directory = {
        truncation_length = 0;
        truncate_to_repo = false;
        style = "bold #82AAFF";
      };

      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };

      git_status = {
        style = "bold #82AAFF";
      };

#      env_var = {
#        all_proxy = {
#          variable = "all_proxy";
#          format = "[$env_value]($style) ";
#          default = "";
#          style = "bold #82AAFF";
#        };
#      };

      cmd_duration = {
        format = "[$duration]($style) ";
      };

      hostname = {
        disabled = true;
      };

      username = {
        disabled = true;
      };

      os = {
        disabled = true;
#        symbols = {
#          Ubuntu = "󰕈 ";
#        };
      };

#      rust = {
#        format = "[$symbol($version )]($style)";
#      };
#
#      nodejs = {
#        format = "[$symbol($version )]($style)";
#      };
#
#      lua = {
#        format = "[$symbol($version )]($style)";
#      };
#
#      golang = {
#        format = "[$symbol($version )]($style)";
#      };
#
#      c = {
#        format = "[$symbol($version(-$name) )]($style)";
#      };
#
#      ruby = {
#        format = "[$symbol($version )]($style)";
#      };
    };
  };
}
