{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/duckdb
    duckdb

    # https://mynixos.com/nixpkgs/package/csvkit
    csvkit
  ];
}
