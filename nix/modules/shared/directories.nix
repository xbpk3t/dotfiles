# Directory structure management
# Migrated from ansible/roles/common/tasks/disk.yml
{ lib, ... }:

{
  # Create standard directories (from ansible disk.yml)
  # Note: This is handled differently on Darwin vs NixOS
  # Darwin: Use launchd or manual creation
  # NixOS: Use systemd.tmpfiles or environment.etc

  # Common directory structure that should exist on all systems:
  # /opt/tools
  # /opt/scripts
  # /opt/database
  # /opt/backup
  # /opt/ops/app
  # /opt/ops/files
  # /var/log/app

  # Platform-specific implementations will be in platform modules
}
