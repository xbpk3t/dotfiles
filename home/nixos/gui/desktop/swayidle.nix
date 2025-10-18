{pkgs, ...}: {
  # Swayidle - idle management daemon for Wayland
  # Handles screen locking, screen blanking, and system suspend on idle
  # 相较于 hypridle/hyprlock，我选择 swayidle/swaylock。因为sway方案的开销更低。swayidle的内存占用只有3MB左右（相较之下 hypridle需要5~10MB）。而swaylock因为激活后没有屏保，所以开销也更低（没有渲染开销）。
  services.swayidle = {
    enable = true;

    # Systemd integration - run as a systemd user service
    systemdTarget = "graphical-session.target";

    # Idle timeout events
    # Adjusted for gradual idle handling:
    # - 5 min: Turn off displays (no lock yet)
    # - 10 min total (5 min after blank): Lock screen
    # - 30 min total: Suspend system
    # This creates a progressive idle flow: blank -> lock -> suspend
    timeouts = [
      # Turn off displays after 5 minutes of inactivity (blank screen without locking)
      {
        timeout = 300;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }

      # Lock screen after another 5 minutes (total 10 min inactivity)
      {
        timeout = 600;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }

      # Suspend system after another 20 minutes (total 30 min inactivity)
      {
        timeout = 1800;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];

    # Events for additional triggers
    events = [
      # Lock screen before sleep (when manually suspending or via timeout)
      {
        event = "before-sleep";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }

      # Optional: Lock screen on explicit lock signal (e.g., from keybind)
      # This ensures consistency if you have a manual lock shortcut
      {
        event = "lock";
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

      # Additional optimizations:
      # - Grace period: Allow a short time to enter password without re-locking immediately
      # 宽限期，避免立即重锁
      grace = 5; # 5 seconds grace period after wake to enter password

      # - Fade-in effect for smoother appearance (minimal overhead)
      # 平滑淡入效果，提升用户体验，几乎无开销
      fade-in = 0.5; # Fade in over 0.5 seconds

      # - Disable screenshot capture for security (prevents grabbing lock screen)
      # 增强安全，防止截屏锁屏
      screenshots = false;
    };
  };
}
