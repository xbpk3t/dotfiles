{mylib, ...}: {
  imports = mylib.scanPaths ./.;

  # MAYBE: jeepney → secretstorage → yt-dlp 报错。之后判断是否需要，如果不需要，就直接删掉，否则fix
  #  programs.yt-dlp = {
  #    enable = true;
  #    package = pkgs.yt-dlp;
  #  };
}
