{...}: {
  # FIXME

  # 1. Hammerspoon file links management
  #  home-manager.users.${username} = {
  #    home.file = {
  #      ".hammerspoon" = {
  #        source = config.lib.file.mkOutOfStoreSymlink ./.hammerspoon;
  #        recursive = true;
  #        # Auto-reload Hammerspoon when config changes
  #        onChange = ''
  #          if pgrep -f "Hammerspoon" > /dev/null; then
  #            echo "Reloading Hammerspoon configuration..."
  #            osascript -e 'tell application "Hammerspoon" to reload config'
  #          fi
  #        '';
  #      };
  #    };
  #  };

  # 2. Ensure directory permissions are correct
  #  system.activationScripts.postUserActivation.text = ''
  #    # Ensure Hammerspoon config directory has correct permissions
  #    if [ -d "/Users/${username}/.hammerspoon" ]; then
  #      chown -R ${username}:staff "/Users/${username}/.hammerspoon"
  #      chmod -R 755 "/Users/${username}/.hammerspoon"
  #    fi
  #  '';
}
