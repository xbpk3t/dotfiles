{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      window = {
        padding = {
          x = 4;
          y = 8;
        };
        decorations = "full";
        startup_mode = "Windowed";
        dynamic_title = true;
        option_as_alt = "Both";
      };
      cursor = {
        style = "Block";
      };
    };
  };
}
