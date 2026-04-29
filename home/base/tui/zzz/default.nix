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
    # https://x.com/jakevin7/status/2046884443508642294 意思是现在支持任意网站了？ https://github.com/jackwener/OpenCLI/pull/343
    #简单来说，这两者现在的关系是 **“深度垂直”** 与 **“广度通用”** 的互补。
    #
    #### **1. Autocli：精致的“手术刀”**
    #* **核心逻辑：** 基于 **站点规则（Adapters）**，针对特定网站（如微信、知乎、Reddit）编写专门的解析代码。
    #* **优点：** * **准：** 结构还原极高，几乎没有杂质。
    #    * **稳：** 针对该站点的交互（如登录、反爬）处理得更好。
    #* **缺点：** * **窄：** 没写规则的站点完全不能用，维护成本高。
    #
    #### **2. OpenCLI (`web read`)：全能的“吸尘器”**
    #* **核心逻辑：** 基于 **Heuristics（启发式算法）**，不分站点，根据 HTML 结构特征（如 `article` 标签、文本密度）强行抽取。
    #* **优点：** * **广：** 支持任意 URL，是处理冷门、小众、个人博客的神器。
    #    * **快：** 一条命令解决 80% 的网页转 Markdown 需求，适合喂给 AI Agent。
    #* **缺点：** * **乱：** 面对结构奇特的页面（SPA、复杂布局）容易误抓侧边栏或漏掉内容。
    #
    #---
    #
    #### **总结判断：该选谁？**
    #
    #| 场景 | 推荐工具 | 理由 |
    #| :--- | :--- | :--- |
    #| **主流内容平台** (微信/知乎等) | **Autocli** | 已经有成熟规则，排版更完美。 |
    #| **临时抓取冷门文档/技术博客** | **OpenCLI** | 通用性强，不需要等作者适配，抓个大概直接给 AI 读。 |
    #| **作为 AI Agent 的组件** | **OpenCLI** | 它通过 [PR #343](https://github.com/jackwener/OpenCLI/pull/343) 整合了通用 Readability 逻辑，更符合“万物皆可 CLI”的自动化思路。 |
    #
    #**一句话建议：** 既然你追求“快省”，**OpenCLI** 现在通过集成 Readability 逻辑，实际上已经吞并了 Autocli 的部分生态位，是你解决“小众站点支持不足”的最优解。

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
