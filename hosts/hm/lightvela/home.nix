{
  mylib,
  ...
}:
{
  imports = [
    (mylib.relativeToRoot "home/hm")
  ];

  # 厂商 PA 当前授权的是 root（hermes-workbench-client）；不建 luck。
  # 如果改用 desk 登录，改成：
  #   username = "desk"; homeDirectory = "/home/desk";
  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
