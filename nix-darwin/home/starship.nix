{...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Inserts a blank line between shell prompts
      add_newline = true;

      # Replace the "❯" symbol in the prompt with "➜"
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # Disable the package module, hiding it from the prompt completely
      package.disabled = true;

      # Configure directory display
      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      # Git configuration
      git_branch = {
        symbol = "🌱 ";
        truncation_length = 20;
        truncation_symbol = "…";
      };

      git_status = {
        conflicted = "🏳";
        ahead = "🏎💨";
        behind = "😰";
        diverged = "😵";
        up_to_date = "✓";
        untracked = "🤷";
        stashed = "📦";
        modified = "📝";
        staged = "[++\($count\)](green)";
        renamed = "👅";
        deleted = "🗑";
      };

      # Language-specific configurations
      golang = {
        symbol = "🐹 ";
      };

      nodejs = {
        symbol = "⬢ ";
      };

      python = {
        symbol = "🐍 ";
      };

      rust = {
        symbol = "🦀 ";
      };
    };
  };
}
