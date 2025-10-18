{
  config,
  lib,
  pkgs,
  ...
}: {
  # Swayidle - idle management daemon for Wayland
  # Handles screen locking, screen blanking, and system suspend on idle
  # 相较于 hypridle/hyprlock，我选择 swayidle/swaylock。因为sway方案的开销更低。swayidle的内存占用只有3MB左右（相较之下 hypridle需要5~10MB）。而swaylock因为激活后没有屏保，所以开销也更低（没有渲染开销）。
  services.swayidle = {
    enable = true;

    # Systemd integration - run as a systemd user service
    systemdTarget = "graphical-session.target";

    # Idle timeout events
    timeouts = [
      # Lock screen after 5 minutes of inactivity
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }

      # Turn off displays after 10 minutes of inactivity
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }

      # Suspend system after 30 minutes of inactivity
      # Commented out by default - uncomment if you want automatic suspend
      # {
      #   timeout = 1800;
      #   command = "${pkgs.systemd}/bin/systemctl suspend";
      # }
    ];

    # Lock screen before sleep (when manually suspending)
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
  };
  
  # Swaylock configuration
  programs.swaylock = {
    enable = true;
    
    settings = {
      # Display settings
      show-failed-attempts = true;
      show-keyboard-layout = false;
      indicator-caps-lock = true;
      
      # Appearance - using stylix colors
      # These will be automatically themed by stylix
      daemonize = true;
      
      # Disable the default background
      # Stylix will handle the background color
      ignore-empty-password = true;
    };
  };
}

