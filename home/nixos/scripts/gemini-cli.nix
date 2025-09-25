{
  config,
  pkgs,
  ...
}: let
  gemini-launcher = pkgs.writeShellScriptBin "gemini-launcher" ''
    #!${pkgs.bash}/bin/bash

    # Define the path to your API key file
    KEY_FILE="${config.home.homeDirectory}/gem.key"

    # Check if the key file exists and is readable
    if [ -f "$KEY_FILE" ]; then
      # Source the API key from the file.
      source "$KEY_FILE"
      # Launch Gemini directly; it will pick up the exported key.
      exec ${pkgs.kitty}/bin/kitty -e ${pkgs.gemini-cli}/bin/gemini
    else
      # If the key file doesn't exist, launch kitty with an informational message, then start gemini.
      exec ${pkgs.kitty}/bin/kitty -e bash -c "echo 'NOTE: Gemini API key file not found at ~/.gem.key.'; echo 'To use a key, create this file with content: export GEMINI_API_KEY=\"YOUR_KEY\"'; echo; echo 'Starting Gemini CLI, which will fall back to web-based login...'; echo; exec ${pkgs.gemini-cli}/bin/gemini"
    fi
  '';
in {
  home.packages = [
    gemini-launcher
  ];

  xdg.desktopEntries.gemini-cli = {
    name = "Gemini CLI";
    comment = "Launch the Gemini CLI in Kitty terminal";
    icon = "utilities-terminal";
    exec = "gemini-launcher";
    terminal = false;
    type = "Application";
    categories = ["Development" "Utility"];
  };
}
