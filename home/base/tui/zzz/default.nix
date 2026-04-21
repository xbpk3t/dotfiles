{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  # https://x.com/aehyok/status/2045021712060936343
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/todoist
    # https://github.com/sachaos/todoist
    todoist

    # https://github.com/larksuite/cli
    # https://x.com/xiaohu/status/2037533774175772773

    # https://x.com/op7418/status/2038450054688915868
    # https://x.com/dotey/status/2038406683865624800

    # 网页转单文件
    # 更推荐使用 autocli. 支持nix安装并且同时占据“快省”两项（但是目前还不够“好”，支持常见站点，但是对于小众站点支持仍不足），注意二者都需要安装chrome拓展
    # https://github.com/jackwener/opencli
    # https://github.com/nashsu/AutoCLI
    #

    # 企业微信cli
    # https://github.com/WecomTeam/wecom-cli

    # vercel-cli

    # 钉钉cli
    # https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli

    # https://mynixos.com/nixpkgs/package/rendercv
    # https://docs.rendercv.com/
    # 直接用yaml写简历，貌似真的不错，网站本身支持在线简历。RenderCV 是一个用于生成高质量简历的引擎，能够从 YAML 输入文件创建 PDF 格式的简历。
    rendercv
  ];

  # https://github.com/mikf/gallery-dl
  # https://mynixos.com/nixpkgs/package/gallery-dl
  # https://mynixos.com/home-manager/options/programs.gallery-dl
  programs.gallery-dl = {
    enable = true;
    settings = {
      extractor.base-directory = "~/Downloads";
    };
  };
}
