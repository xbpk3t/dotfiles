{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.fetch;

  driverPkg =
    {
      inherit (pkgs) microfetch macchina;
    }
    .${cfg.driver};
in
{
  options.modules.devops.fetch = {
    enable = lib.mkEnableOption "system fetch (`ff`)";

    driver = lib.mkOption {
      type = lib.types.enum [
        "microfetch"
        "macchina"
      ];
      default = "microfetch";
      description = "Backend used by the `ff` shell alias.";
    };
  };

  config = lib.mkIf cfg.enable {
    # macchina is installed by programs.macchina below.
    home.packages = lib.optionals (cfg.driver == "microfetch") [ pkgs.microfetch ];

    # The user-facing entry point stays `ff` regardless of the selected driver.
    # Why alias instead of a wrapper: this repo treats zsh as the interactive
    # shell, and the driver is selected statically per host at eval time.
    programs.zsh.shellAliases.ff = lib.mkDefault (lib.getExe driverPkg);

    programs.macchina = lib.mkIf (cfg.driver == "macchina") {
      enable = true;

      settings = {
        theme = "ff";

        # Keep the order close to the old fastfetch config. Readouts that are
        # unavailable on a host (e.g. Battery/GPU on a headless VPS) are
        # silently omitted by macchina.
        show = [
          "Host"
          "Distribution"
          "Kernel"
          "Packages"
          "Shell"
          "DesktopEnvironment"
          "WindowManager"
          "Machine"
          "Processor"
          "ProcessorLoad"
          "Memory"
          "DiskSpace"
          "Resolution"
          "Battery"
          "GPU"
          "Uptime"
          "Terminal"
          "Backlight"
        ];

        # Required for the DiskSpace readout.
        disks = [ "/" ];

        memory_percentage = true;
        disk_space_percentage = true;
      };

      themes.ff = {
        separator = "->";
        spacing = 2;
        key_color = "Magenta";
        separator_color = "Cyan";

        keys = {
          host = "User";
          distro = "OS";
          de = "Desktop";
          disk_space = "Disk";
          backlight = "Brightness";
        };
      };
    };
  };
}
