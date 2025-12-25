{pkgs, ...}: {
  # [Archlinux 笔记本省电设置 - 少数派](https://sspai.com/post/101744)
  # 启用 powertop、TLP、upower、CPU governor 以及键盘背光 udev 规则
  # 针对笔记本，VPS 没有电池/背光，额外服务 (`powertop.service`, `tlp.service`) 只会占资源，还可能修改 CPU governor 影响性能稳定性

  # [2025-12-23]
  # 之前配置文件里有 TLP, Powertop, cpuFreqGovernor 三套“管控 CPU/省电”的东西，所以会互相覆盖。最终决定只保留TLP，移除其他两项。
  # 为何选择TLP，具体说明
  ## Linux中有 TLP、PPD、Powertop、auto-cpufreq、cpuFreqGovernor 这些省电相关工具
  ## TLP完全支持以下比较项，而其他工具则或多或少都有一些不支持的，所以选择TLP
  ## CPU 策略 (governor/EPP/boost)
  ## 设备级省电 (PCIe/SATA 等)
  ## USB autosuspend/黑名单
  ## Wi-Fi 省电
  ## AC/BAT 自动切换

  environment.systemPackages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/powertop
    powertop
  ];

  # Disable power-profiles-daemon to avoid conflicts with TLP
  # 启用TLP，所以关闭PPD，否则会被抢夺控制权
  services.power-profiles-daemon.enable = false;

  # noctalia的battery会报错 No battery detected，通过 upower 解决该问题
  # 电池信息/桌面电源事件（一般建议开着）
  services.upower.enable = true;

  # https://mynixos.com/nixpkgs/options/services.tlp
  # https://linrunner.de/tlp/index.html
  # Enable TLP for advanced power management
  # 只会占资源，还可能修改 CPU governor 影响性能稳定性
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

      # 当 AC 被拔掉时，恢复你配置的充电阈值（常用于你跑过 tlp fullcharge / recalibrate 之后想尽快回到自定义阈值）
      RESTORE_THRESHOLDS_ON_BAT = 1;

      # WiFi powersave: off on AC for reliability, on battery for savings
      # https://linrunner.de/tlp/settings/network.html#wifi-pwr-on-ac-bat
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # USB autosuspend: enable to power down idle USB devices
      # https://linrunner.de/tlp/settings/usb.html
      # 禁用自动挂起（否则如果是蓝牙鼠标之类的，就会在很短时间内断开连接，很麻烦）
      USB_AUTOSUSPEND = 0;

      # Disable Bluetooth on startup if not needed
      # [2025-11-04] 开启该配置，会自动禁用蓝牙设备（比如说　我的蓝牙耳机显示为connected，但是每次都需要手动连接）
      # DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth";

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
  # https://mynixos.com/nixpkgs/options/powerManagement
  powerManagement = {
    enable = true;
    # https://mynixos.com/nixpkgs/option/powerManagement.cpuFreqGovernor
    # 关闭 cpuFreqGovernor（默认就是null，为了说明整个省电相关配置均由TLP接管，所以显式声明）
    cpuFreqGovernor = null;
    # 关闭 auto-tune（Powertop 只当分析工具）
    powertop.enable = false;
  };

  # Kernel parameters for AMD CPUs: enable active mode for better power management
  # This assumes an AMD CPU; remove if using Intel
  # [2025-12-23] 注释该配置
  #  boot.kernelParams = [
  #    # 告诉ACPI固件，当前运行linux。解决ACPI兼容性问题。
  #    "acpi_osi=Linux"
  #    # passive/active 分别是 省电模式、性能模式。如果不填就是自动调度。
  #    "intel_pstate=active"
  #  ];

  # 使用 services.udev.extraRules 来设置默认亮度
  # 这里要注意不同品牌的机器，这里的 /sys/class/leds/platform 这部分参数不同。之后再做优化。
  # 默认关闭键盘背光灯
  # [2025-12-23] 注释该配置
  #  services.udev.extraRules = ''
  #    SUBSYSTEM=="leds", ATTR{name}=="platform::kbd_backlight", RUN+="${pkgs.coreutils}/bin/echo 0 > /sys/class/leds/platform::kbd_backlight/brightness"
  #  '';
}
