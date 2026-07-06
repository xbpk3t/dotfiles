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

  ];
}
