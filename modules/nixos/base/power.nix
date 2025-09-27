{
  # [Archlinux 笔记本省电设置 - 少数派](https://sspai.com/post/101744)

  # Disable power-profiles-daemon to avoid conflicts with TLP
  services.power-profiles-daemon.enable = false;

  # Enable TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      # CPU scaling governors: performance on AC for speed, powersave on battery for efficiency
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # CPU energy performance policies: prioritize performance on AC, maximum power saving on battery
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # CPU boost: enable on AC for better responsiveness, disable on battery to save power
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Platform profiles: performance on AC, low-power on battery for overall system efficiency
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # Battery charge thresholds: start charging at 75%, stop at 80% to prolong battery lifespan
      # Adjust these based on your needs; lower thresholds extend life but reduce capacity
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # Restore thresholds automatically when switching back to AC after full charge
      RESTORE_THRESHOLDS_ON_BAT = 1;

      # WiFi powersave: off on AC for reliability, on battery for savings
      WIFI_POWERSAVE_ON_AC = 0;
      WIFI_POWERSAVE_ON_BAT = 1;

      # USB autosuspend: enable to power down idle USB devices
      USB_AUTOSUSPEND = 1;

      # Your existing USB denylist for specific quirks
      USB_DENYLIST = "2357:0601 0bda:5411";

      # Disable Bluetooth on startup if not needed
      DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth";

      # Runtime power management for PCIe devices: on for savings
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Disk power management: more aggressive on battery
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "min_power";

      # Sound card power saving
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
    };
  };

  # Enable Powertop for automatic power tuning and analysis
  # This complements TLP by applying additional optimizations
  powerManagement.powertop.enable = true;

  # Kernel parameters for AMD CPUs: enable active mode for better power management
  # This assumes an AMD CPU; remove if using Intel
  boot.kernelParams = ["amd_pstate=active"];
}
