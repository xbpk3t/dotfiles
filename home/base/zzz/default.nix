{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  # https://x.com/aehyok/status/2045021712060936343
  home.packages = with pkgs; [
    # vercel-cli

    # https://docs.rendercv.com/
    # 直接用yaml写简历，貌似真的不错，网站本身支持在线简历。RenderCV 是一个用于生成高质量简历的引擎，能够从 YAML 输入文件创建 PDF 格式的简历。
    rendercv
  ];

  # https://github.com/mikf/gallery-dl
  # https://mynixos.com/home-manager/options/programs.gallery-dl
  programs.gallery-dl = {
    enable = true;
    settings = {
      extractor.base-directory = "~/Downloads";
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
