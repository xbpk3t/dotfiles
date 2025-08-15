# NixOS security configuration
# Migrated from ansible/roles/common/tasks/firewall.yml
{ ... }:

{
  # SELinux configuration (from ansible firewall.yml)
  # Note: NixOS doesn't use SELinux by default, uses AppArmor instead
  security = {
    # AppArmor (NixOS equivalent of SELinux)
    apparmor = {
      enable = false; # Disabled for K8s compatibility (like ansible)
    };

    # Sudo configuration
    sudo = {
      enable = true;
      wheelNeedsPassword = false; # For ops convenience
    };
  };

  # System security settings
  boot = {
    # Kernel security
    kernelParams = [
      # Disable various attack vectors
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
    ];
  };
}
