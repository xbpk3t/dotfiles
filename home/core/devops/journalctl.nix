{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lazyjournal
  ];

  home.file.".config/lazyjournal/config.yml" = {
    source = ./lazyjournal.yml;
    force = true;
  };
}
