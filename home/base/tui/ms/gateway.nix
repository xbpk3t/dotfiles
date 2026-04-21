{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/caddy
    # 注意并不打算用来启动本地 web-server，只是打算作为 caddy validate & fmt 使用
    caddy
  ];
}
