{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/todoist
    # https://github.com/sachaos/todoist
    todoist

    # https://github.com/larksuite/cli
    # https://x.com/xiaohu/status/2037533774175772773

    # https://x.com/op7418/status/2038450054688915868
    # https://x.com/dotey/status/2038406683865624800

    # https://github.com/jackwener/opencli

    # vercel-cli
    # https://mynixos.com/nixpkgs/package/nodePackages.vercel

    # 钉钉cli
    # https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli

    # https://mynixos.com/nixpkgs/package/tshark
    #
    tshark
    # https://mynixos.com/nixpkgs/package/termshark
    # https://github.com/gcla/termshark
  ];
}
