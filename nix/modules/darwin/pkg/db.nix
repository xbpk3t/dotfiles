{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # 数据库工具
    # mysql80  # 大型依赖，暂时移除
    # pgloader

    # mysql-client # https://mynixos.com/nixpkgs/package/mysql-client
    # postgresql # https://mynixos.com/nixpkgs/package/postgresql
  ];
}
