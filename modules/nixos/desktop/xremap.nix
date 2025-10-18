{
  myvars,
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.xremap;
in {
  # https://github.com/xremap/xremap
  # [xremap/nix-flake](https://github.com/xremap/nix-flake/)
  # [petrstepanov/gnome-macos-remap-wayland: macOS like keyboard remap for GNOME desktop environment. Works with Wayland and X11.](https://github.com/petrstepanov/gnome-macos-remap-wayland)
  # [Mastering Key Remapping on Linux: A Practical Guide with xremap · Paolo Mainardi](https://www.paolomainardi.com/posts/linux-remapping-keys-with-xremap/)
  # https://www.youtube.com/watch?v=UPWkQ3LUDOU

  #  hardware.uinput.enable = true;
  #  users.groups.uinput.members = [ myvars.username ];
  #  users.groups.input.members = [ myvars.username ];

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.xremap];

    services.xremap = {
      # 注意如果设置为 serviceMode = user，无法识别到设备列表，导致失败
      #    serviceMode = "user";
      serviceMode = "system";
      # debug = true;
      userName = myvars.username;

      withWlroots = true;
      watch = true;

      config = {
        keymap = [
          #        # ============================================================
          #        # Mac-like Global Shortcuts
          #        # ============================================================
          #        {
          #          name = "Mac-like Global Shortcuts";
          #          remap = {
          #            # Basic editing - use Super (Command) key like macOS
          #            "Super-c" = "C-c"; # Copy
          #            "Super-v" = "C-v"; # Paste
          #            "Super-x" = "C-x"; # Cut
          #            "Super-a" = "C-a"; # Select all
          #            "Super-z" = "C-z"; # Undo
          #            "Super-Shift-z" = "C-Shift-z"; # Redo
          #            "Super-s" = "C-s"; # Save
          #            "Super-f" = "C-f"; # Find
          #            "Super-w" = "C-w"; # Close tab/window
          #            "Super-q" = "Alt-F4"; # Quit application
          #            "Super-t" = "C-t"; # New tab
          #            "Super-n" = "C-n"; # New window
          #            "Super-r" = "C-r"; # Refresh
          #
          #            # Navigation
          #            "Super-Left" = "Home"; # Beginning of line
          #            "Super-Right" = "End"; # End of line
          #            "Super-Up" = "C-Home"; # Beginning of document
          #            "Super-Down" = "C-End"; # End of document
          #
          #            # Tab navigation
          #            "Super-Shift-LeftBrace" = "C-Shift-Tab"; # Previous tab
          #            "Super-Shift-RightBrace" = "C-Tab"; # Next tab
          #
          #            # CapsLock to Escape (useful for vim users)
          #            "CapsLock" = "Esc";
          #          };
          #        }
          #
          #        # ============================================================
          #        # Terminal-specific mappings
          #        # ============================================================
          {
            name = "Terminal Mac-like shortcuts";
            application = {
              only = [
                "foot"
                "kitty"
                "wezterm"
                "alacritty"
                "gnome-terminal"
                "konsole"
                "terminator"
                "xterm"
              ];
            };
            remap = {
              # In terminals, use Super for copy/paste instead of Ctrl+Shift
              "Super-c" = "C-Shift-c"; # Copy in terminal
              "Super-v" = "C-Shift-v"; # Paste in terminal
              "Super-t" = "C-Shift-t"; # New tab in terminal
              "Super-w" = "C-Shift-w"; # Close tab in terminal
              "Super-n" = "C-Shift-n"; # New window in terminal
              "Super-f" = "C-Shift-f"; # Find in terminal

              # Keep Ctrl+C for interrupt signal
              # "C-c" remains as is for SIGINT
            };
          }
          #
          #        # ============================================================
          #        # Browser-specific mappings
          #        # ============================================================
          #        {
          #          name = "Browser Mac-like shortcuts";
          #          application = {
          #            only = [
          #              "firefox"
          #              "chromium"
          #              "google-chrome"
          #              "brave"
          #            ];
          #          };
          #          remap = {
          #            # Tab navigation (already handled by global, but can be customized)
          #            "Super-Shift-LeftBrace" = "C-Shift-Tab"; # Previous tab
          #            "Super-Shift-RightBrace" = "C-Tab"; # Next tab
          #            "Super-l" = "C-l"; # Focus address bar
          #            "Super-Shift-Delete" = "C-Shift-Delete"; # Clear browsing data
          #          };
          #        }
          #
          #        # ============================================================
          #        # Text Editor shortcuts
          #        # ============================================================
          #        {
          #          name = "Text Editor Mac-like shortcuts";
          #          application = {
          #            only = [
          #              "code"
          #              "codium"
          #              "nvim"
          #              "gvim"
          #              "gedit"
          #              "kate"
          #            ];
          #          };
          #          remap = {
          #            # Command palette
          #            "Super-Shift-p" = "C-Shift-p";
          #            # Go to file
          #            "Super-p" = "C-p";
          #            # Comment/uncomment
          #            "Super-Slash" = "C-Slash";
          #          };
          #        }
          #
          #        # ============================================================
          #        # Navigation with Alt (Option) key - vim-like
          #        # ============================================================
          #        {
          #          name = "Alt-based navigation";
          #          remap = {
          #            "M-h" = "Left";
          #            "M-j" = "Down";
          #            "M-k" = "Up";
          #            "M-l" = "Right";
          #            "M-Shift-h" = "Home";
          #            "M-Shift-j" = "PageDown";
          #            "M-Shift-k" = "PageUp";
          #            "M-Shift-l" = "End";
          #          };
          #        }
        ];
      };
    };
  };
}
