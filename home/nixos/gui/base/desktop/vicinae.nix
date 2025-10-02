{...}: {
  services.vicinae = {
    enable = true;
    autoStart = true;
    settings = {
      faviconService = "google"; # twenty | google | none
      font.size = 11;

      popToRootOnClose = true;
      rootSearch = {
        searchFiles = false;
      };

      theme = {
        name = "rosepine-dawn";
      };

      window = {
        csd = true;
        opacity = 0.95;
        rounding = 16;
      };
    };
  };
}
