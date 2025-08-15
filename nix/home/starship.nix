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
    };
  };
}
