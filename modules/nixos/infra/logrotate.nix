# 通用 logrotate 能力（文件日志轮转）。
#
# 这是通用基础设施，不属于 fail2ban/clamav/security-server 任何一个角色。
# fail2ban 在 NixOS 下默认 logtarget=SYSLOG，本身不需要它；
# 只有写文件日志的服务（例如 clamav、caddy、nginx）才需要启用。
#
# 默认关闭；host 或具体服务模块按需启用并追加 settings。
{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.infra.logrotate;
in
{
  options.modules.infra.logrotate = {
    enable = lib.mkEnableOption "logrotate (file-based log rotation)";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "logrotate configuration passed to services.logrotate.settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.logrotate = {
      enable = true;
      inherit (cfg) settings;
    };
  };
}
