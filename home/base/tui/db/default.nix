{
  pkgs,
  mylib,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # 数据库工具
    # mysql80  # 大型依赖，暂时移除
    # pgloader

    # https://mynixos.com/nixpkgs/package/mysql-client
    # mysql-client

    # https://mynixos.com/nixpkgs/package/postgresql
    # postgresql

    #    mycli
    #    pgcli
    #    mongosh

    # https://mynixos.com/nixpkgs/package/sqlite
    sqlite
    # https://mynixos.com/nixpkgs/package/sqlite-utils
    # https://github.com/simonw/sqlite-utils
    # https://sqlite-utils.datasette.io/
    sqlite-utils

    # https://mynixos.com/nixpkgs/package/usql
    # https://github.com/xo/usql
    # what: 给 pgsql, mysql, oracle, sqlite 之类RDB提供的统一cli工具
    # usql

    # https://mynixos.com/nixpkgs/package/sqldef
    # why: 你迟早会改 schema（加列、加索引、加约束）。sqldef 的思路是：维护一份“期望的完整 DDL”，它帮你diff 并把库迁移到目标状态（幂等、适合脚本/CI）。
    # sqldef

    # https://github.com/simonw/csvs-to-sqlite
    # https://mynixos.com/nixpkgs/package/csvs-to-sqlite
    # csvs-to-sqlite

    # https://mynixos.com/nixpkgs/package/duckdb
    duckdb

    # https://mynixos.com/nixpkgs/package/csvkit
    csvkit
  ];
}
