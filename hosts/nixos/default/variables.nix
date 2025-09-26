{
  # Git configuration
  gitUsername = "luck";
  gitEmail = "yyzw@live.com";

  # Display Manager
  displayManager = "sddm";

  # Theme and style configuration

  # System preferences
  browser = "floorp";
  terminal = "wezterm";
  keyboardLayout = "us";
  consoleKeyMap = "us";

  # Hardware configuration
  gpuType = "nvidia";
  hostId = "5ab03f50";

  # Hyprland Settings
  # Examples:
  # extraMonitorSettings = "monitor = Virtual-1,1920x1080@60,auto,1";
  # extraMonitorSettings = "monitor = HDMI-A-1,1920x1080@60,auto,1";
  # You can configure multiple monitors.
  # Inside the quotes, create a new line for each monitor.
  extraMonitorSettings = "

    ";

  # For hybrid support (Intel/NVIDIA Prime or AMD/NVIDIA)
  intelID = "PCI:1:0:0";
  amdgpuID = "PCI:5:0:0";
  nvidiaID = "PCI:0:2:0";

  # Flatpak configuration
  flatpakEnable = true;

  # Development tools
  dockerEnable = true;
  virtManagerEnable = false;

  # Media and graphics
  blenderEnable = false;
  kritaEnable = false;
}
