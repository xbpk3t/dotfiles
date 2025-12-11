{pkgs, ...}: {
  home.packages = with pkgs; [
    # 数据库工具
    # mysql80  # 大型依赖，暂时移除
    # pgloader

    # mysql-client # https://mynixos.com/nixpkgs/package/mysql-client
    # postgresql # https://mynixos.com/nixpkgs/package/postgresql

    #    mycli
    #    pgcli
    #    mongosh
    #    sqlite

    # https://mynixos.com/nixpkgs/package/duckdb
    duckdb

    # https://mynixos.com/nixpkgs/package/csvkit
    csvkit
  ];
}
