# Darwin system limits configuration
# Migrated from ansible/roles/common/tasks/ulimit.yml
_: {
  # macOS system limits (equivalent to ansible ulimit.yml)
  # Note: macOS handles limits differently than Linux

  # Set system-wide limits using launchd
  launchd.daemons.limit-maxfiles = {
    command = "/bin/launchctl limit maxfiles 1048576 1048576";
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = ["/bin/launchctl" "limit" "maxfiles" "1048576" "1048576"];
      RunAtLoad = true;
    };
  };

  launchd.daemons.limit-maxproc = {
    command = "/bin/launchctl limit maxproc 32768 32768";
    serviceConfig = {
      Label = "limit.maxproc";
      ProgramArguments = ["/bin/launchctl" "limit" "maxproc" "32768" "32768"];
      RunAtLoad = true;
    };
  };
}
