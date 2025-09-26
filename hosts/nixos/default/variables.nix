{
  # Git configuration
  gitUsername = "luck";
  gitEmail = "yyzw@live.com";

  # Display Manager
  displayManager = "sddm";

  # Application toggles
  tmuxEnable = false;
  alacrittyEnable = false;
  weztermEnable = true;
  ghosttyEnable = false;
  vscodeEnable = true;
  helixEnable = false;
  doomEmacsEnable = false;

  # Theme and style configuration
  stylixImage = ../../wallpapers/mountainscapedark.jpg;
  waybarChoice = ../../modules/home/waybar/waybar-curved.nix;
  animChoice = ../../modules/home/hyprland/animations-def.nix;

  # System preferences
  browser = "floorp";
  terminal = "wezterm";
  keyboardLayout = "us";

  # Hardware configuration
  gpuType = "nvidia";
  hostId = "5ab03f50";

  # Flatpak configuration
  flatpakEnable = true;

  # Gaming configuration
  steamEnable = true;
  minecraftEnable = false;

  # Development tools
  dockerEnable = true;
  podmanEnable = false;
  virtManagerEnable = false;

  # Media and graphics
  blenderEnable = false;
  kritaEnable = false;
}