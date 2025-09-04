# Darwin directory structure management
# Migrated from ansible/roles/common/tasks/disk.yml
# Contains directory configuration that can be shared between multiple hosts
_: {
  # Create standard directories on macOS
  # Note: macOS doesn't have systemd-tmpfiles, so we use launchd

  # Create directories using a launch daemon
  launchd.daemons.create-directories = {
    serviceConfig = {
      Label = "create.directories";
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          # Create standard directories (from ansible disk.yml)
          mkdir -p /opt/tools /opt/scripts /opt/database /opt/backup
          mkdir -p /opt/ops/app /opt/ops/files
          mkdir -p /var/log/app

          # Set permissions
          chown -R ops:ops /opt/ops
          chmod -R 755 /opt/ops
          chmod 755 /var/log/app
        ''
      ];
      RunAtLoad = true;
      StandardOutPath = "/var/log/create-directories.log";
      StandardErrorPath = "/var/log/create-directories.log";
    };
  };

  # Note: Host-specific directory configurations should be added per-host
}
