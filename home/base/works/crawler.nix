_: {
  # https://github.com/mikf/gallery-dl
  # https://mynixos.com/home-manager/options/programs.gallery-dl
  programs.gallery-dl = {
    enable = true;
    settings = {
      extractor.base-directory = "~/Downloads";
    };
  };
}
