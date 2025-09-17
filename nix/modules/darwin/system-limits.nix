# Darwin system limits configuration
# Migrated from ansible/roles/common/tasks/ulimit.yml
_: {
  # macOS system limits (equivalent to ansible ulimit.yml)
  # Note: macOS handles limits differently than Linux

  # Note: System limits are managed by macOS defaults
  # If you need custom limits, you can set them manually with:
  # sudo launchctl limit maxfiles 1048576 1048576
  # sudo launchctl limit maxproc 32768 32768
}
