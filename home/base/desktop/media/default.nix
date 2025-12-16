{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  programs.yt-dlp = {
    enable = true;
    package = pkgs.yt-dlp;
  };
}
