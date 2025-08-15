# NixOS directory structure management
# Migrated from ansible/roles/common/tasks/disk.yml
{ ... }:

{
  # Create standard directories using systemd-tmpfiles
  # Equivalent to ansible disk.yml directory creation
  systemd.tmpfiles.rules = [
    # Standard directories (from ansible disk.yml)
    "d /opt/tools 0755 root root -"
    "d /opt/scripts 0755 root root -"
    "d /opt/database 0755 root root -"
    "d /opt/backup 0755 root root -"

    # Ops user directories (from ansible disk.yml)
    "d /opt/ops 0755 ops ops -"
    "d /opt/ops/app 0755 ops ops -"
    "d /opt/ops/files 0755 ops ops -"

    # Log directories (from ansible disk.yml)
    "d /var/log/app 0755 root root -"

    # Root user directories (from ansible disk.yml)
    "d /root/.pip 0755 root root -"
  ];
}
