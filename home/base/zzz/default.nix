{
  mylib,
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.zzz;
in
{
  options.modules.zzz.enable = lib.mkEnableOption "misc tools (rendercv + docs API env vars)";

  imports = mylib.scanPaths ./.;

  config = lib.mkIf cfg.enable {
    # https://x.com/aehyok/status/2045021712060936343
    home.packages = [
      # vercel-cli

      # https://docs.rendercv.com/
      # 直接用yaml写简历，貌似真的不错，网站本身支持在线简历。RenderCV 是一个用于生成高质量简历的引擎，能够从 YAML 输入文件创建 PDF 格式的简历。
      pkgs.rendercv
    ];

    # For docs-alfred data-cli enrich Movie/TV/books/...
    home.sessionVariables = {
      GOOGLE_CLOUD_API_KEY = "$(cat ${config.sops.secrets.GOOGLE_CLOUD_API_KEY.path})";
      TMDB_API_KEY = "$(cat ${config.sops.secrets.API_TMDB.path})";
    };
  };

  #programs.gallery-dl = {
  #enable = true;
  #settings = {
  #  extractor.base-directory = "./";
  #  extractor.directory = ["{manga}" "{manga} c{chapter} - {title}"];
  #  extractor.mangadex = {
  #        lang = ["fa" "en"];
  #        postprocessors = {
  #    "name" = "zip";
  #    "compression" = "lzma";
  #    "extension" = "cbz";
  #};
}
