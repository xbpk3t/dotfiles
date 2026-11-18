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

    # freeMemThreshold / freeSwapThreshold 直接用 nixpkgs services.earlyoom
    # 的选项（默认同为 10），不再另设一层同名包装。

    prefer = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "chromium"
        "chrome"
        "claude"
        "node"
        "MainThread"
        "nix.*"
        "[.]claude-wrapped"
      ];
      description = ''
        Process-name regexes to prefer killing when memory is tight.
        earlyoom matches these against /proc/<pid>/comm only (first 15
        bytes); it does not look at the command line.

        Avoid backslash escapes: nixpkgs passes these through the
        EARLYOOM_ARGS environment string, and systemd's $EARLYOOM_ARGS
        expansion consumes them before earlyoom sees the regex. Use
        character classes (e.g. [.]foo) instead.
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
      reportInterval = 0;
      # earlyoom 只匹配 /proc/<pid>/comm，不含路径，锚定首尾即可。
      extraArgs = [
        "--prefer"
        "^(${lib.concatStringsSep "|" cfg.prefer})$"
        "--avoid"
        "^(${lib.concatStringsSep "|" cfg.avoid})$"
      ];
    };
  };
}
