{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # API

    # redocly

    # = swaggo/swag
    # tags(desc): 代码生成 > API文档 > OpenAPI
    go-swag

    # tags(desc): 工程脚手架 > CLI框架 > 代码生成
    cobra-cli
  ];
}
