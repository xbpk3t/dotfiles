{
  mylib,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.sys.basePackages;
in
{
  options.modules.sys.basePackages.enable =
    lib.mkEnableOption "API scaffolding tools (go-swag / cobra-cli)";

  imports = mylib.scanPaths ./.;

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      # API

      # redocly

      # = swaggo/swag
      # tags(desc): 代码生成 > API文档 > OpenAPI
      go-swag

      # tags(desc): 工程脚手架 > CLI框架 > 代码生成
      cobra-cli
    ]
  );
}
