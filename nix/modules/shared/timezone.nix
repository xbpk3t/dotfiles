# Timezone and NTP configuration
# Migrated from ansible/roles/common/tasks/timezone.yml
{ lib, ... }:

{
  # Set timezone (equivalent to ansible common_timezone)
  time.timeZone = "Asia/Shanghai";

  # NTP configuration is handled differently on Darwin vs NixOS
  # Darwin: handled by system preferences
  # NixOS: handled by systemd-timesyncd or chrony
}
