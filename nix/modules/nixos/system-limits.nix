# NixOS system limits configuration
# Migrated from ansible/roles/common/tasks/ulimit.yml
{ ... }:

{
  # System limits (equivalent to ansible ulimit.yml)
  security.pam.loginLimits = [
    # File descriptor limits (from ansible ulimit.yml)
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "1048576";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }

    # Process limits
    {
      domain = "*";
      type = "soft";
      item = "nproc";
      value = "32768";
    }
    {
      domain = "*";
      type = "hard";
      item = "nproc";
      value = "32768";
    }

    # Core dump limits (from ansible ulimit.yml)
    {
      domain = "*";
      type = "soft";
      item = "core";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "unlimited";
    }
  ];

  # Systemd service limits (equivalent to ansible system.conf changes)
  systemd.extraConfig = ''
    DefaultLimitCORE=infinity
    DefaultLimitNOFILE=1048576
    DefaultLimitNPROC=32768
  '';
}
