{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.kernel.earlyoom;
in
{
  options.modules.kernel.earlyoom = {
    enable = lib.mkEnableOption "earlyoom userspace OOM killer";

    freeMemThreshold = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 10;
      description = ''
        Minimum available memory (percent) before earlyoom starts killing.
      '';
    };

    freeSwapThreshold = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 10;
      description = ''
        Minimum free swap (percent) before earlyoom starts killing.
      '';
    };

    prefer = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "chromium"
        "chrome"
        "claude"
        "node"
        "nix"
        "\\.claude-wrapped"
      ];
      description = ''
        Process-name regexes to prefer killing when memory is tight.
        Matched against /proc/<pid>/comm and cmdline by earlyoom.
      '';
    };

    avoid = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "systemd"
        "sshd"
        "Xvfb"
        "x11vnc"
        "openbox"
      ];
      description = ''
        Process-name regexes to avoid killing, so the box stays reachable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd-oomd 与 earlyoom 二选一。当前 oomd 没有监控任何 cgroup
    # （oomctl 的监控列表为空），留着只会让状态读数产生误导。
    systemd.oomd.enable = lib.mkForce false;

    services.earlyoom = {
      enable = true;
      inherit (cfg) freeMemThreshold freeSwapThreshold;
      reportInterval = 0;
      extraArgs = [
        "--prefer" "(^|/)(${lib.concatStringsSep "|" cfg.prefer})$"
        "--avoid" "(^|/)(${lib.concatStringsSep "|" cfg.avoid})$"
      ];
    };
  };
}
