# Darwin host configuration
# This file contains host-specific configurations that should not be shared between different machines
{myvars, ...}: {
  # PLAN [2025-10-08] 目前 username 仍然用的是全局的。应该是不同host可以设置各自的username，才是合理的方案

  # Host-specific overrides for system defaults
  # These will override the defaults set in modules/darwin/system.nix
  system.defaults = {
    # Host-specific dock settings (overrides module defaults)
    dock = {
      tilesize = 2; #
      largesize = 16; # 16 < size < 128
      # Other dock settings will use module defaults
    };

    # Host-specific login window text
    loginwindow = {
      autoLoginUser = myvars.username;
    };

    # Any other host-specific system defaults can be added here
    # They will override the module defaults due to import order
  };

  # Host-specific network configuration (overrides module defaults)
  networking = {
    hostName = "${myvars.username}";
    computerName = "${myvars.username}";
    localHostName = "${myvars.username}";
  };

  # Host-specific user overrides (if needed)
  # users.users.${username}.description = "Custom description for this host";

  # Host-specific Nix settings (if different from module defaults)
  # nix.settings.trusted-users = [username "additional-user"];

  # Host-specific launchd services (in addition to module defaults)
  # launchd.agents = {
  #   "host-specific-service" = {
  #     serviceConfig = {
  #       Label = "com.host.specific.service";
  #       # ... service configuration
  #     };
  #   };
  # };

  # Any other host-specific configurations can be added here
  # They will override or extend the module configurations

  # 系统级配置启用
  modules = {
    networking = {
      singbox.enable = true;
    };
  };
}
