{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.modules.extra.jetbrains-remote;
  # 之前只用一个 packages 列表同时给 home.packages 和 ides，
  # 这会把“运行时 JDK”也塞进 ides（语义不对），并且 IDE 可能不带 JBR 导致远端自检失败。
  # 现在把“IDE”和“运行时”拆开：ides 只放 IDE，JDK 单独装并显式指定给 GoLand。
  idePkgs = with pkgs; [
    # jetbrains.goland
    # https://mynixos.com/nixpkgs/package/jetbrains.goland
    jetbrains.goland
  ];
  # 远端是 headless，只需要运行时，不需要 JCEF；用 jdk-no-jcef 更轻也更匹配用途
  runtimePkgs = with pkgs; [
    # https://mynixos.com/nixpkgs/package/jetbrains.jdk-no-jcef
    jetbrains.jdk-no-jcef
  ];
in {
  options.modules.extra.jetbrains-remote = with lib; {
    enable = mkEnableOption "Jetbrains IDE Remote Development Enable";
  };

  # 怎么排查 jetbrains remote 服务相关问题？
  #
  # 最重要的排查方向只有两个：
  ## 远端 IDE 进程到底有没有真正启动？（如果启动了，是否输出了可被 Toolbox 解析的 Join Link？）
  ## 远端运行时/JDK 和启动参数是否正确？（JDK 路径是否正确？是否被 vmoptions 或 javaagent 干扰？）
  #
  #
  #
  #
  #
  #
  # 常见根因清单（按概率排序）
  #
  # 1. **JDK/JBR 路径错误**（尤其是 NixOS / 非标准安装）
  # 2. **vmoptions 注入 javaagent / 破解类输出**导致 stdout 解析失败
  # 3. **Toolbox 实际启动旧版本**，但你配置修改的是新版本
  # 4. **远端 IDE 进程确实启动了但 stdout 被污染**（多个输出）
  # 5. **网络问题导致连接超时**（较少，但仍需检查）

  #
  # # 远端运行状态
  # goland-remote-dev-server status

  # # 远端环境变量
  # printenv | rg -i 'GOLAND_JDK|IDEA_JDK|JAVA'

  # # Toolbox 实际启动路径
  # cat ~/.local/share/JetBrains/Toolbox/channels/Goland-*.json

  # # vmoptions 是否有 javaagent
  # rg -n 'javaagent|ja-netfilter' ~/.config/JetBrains/GoLand*/goland64.vmoptions

  # # 手动启动看看 stdout
  # /nix/store/.../goland/bin/goland serverMode /path/to/project

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/package/jetbrains.gateway

    # 相较于原配置：除了 IDE，还显式安装 JDK 运行时，避免 IDE 包本身不带 JBR 导致远端自检失败
    home.packages = idePkgs ++ runtimePkgs;

    # https://mynixos.com/home-manager/options/programs.jetbrains-remote
    programs.jetbrains-remote = {
      enable = true;
      # 相较于原配置：ides 只放 IDE 包，避免把 JDK 错当成 IDE 交给 remote system
      ides = idePkgs;
    };

    # RD不需要该env，所以注释掉
    # home.sessionVariables = {
    #   # JetBrains IDE（含 GoLand）启用 Wayland 渲染；新版本默认支持，老版本需此开关
    #   "JBR_ENABLE_WAYLAND" = "1";
    # };

    # 相较于原配置：显式告诉 GoLand 使用这个 JDK（NixOS 上 IDE 包常不带 jbr/ 运行时）
    # 这样可以绕开“远端自检失败/找不到运行时”的问题
    home.sessionVariables = {
      # 之前的配置 goland remote server 找不到 lib/server/libjvm.so，所以修改
      # 远端环境变量 GOLAND_JDK 当前值是 JDK 包根目录，而 GoLand 远端启动器期望 GOLAND_JDK 指向一个包含 lib/server/libjvm.so 的目录。Nix 的 JDK 布局是 lib/openjdk/lib/server，所以路径不匹配。

      # 我在远端用临时变量验证后，可以正常启动：

      # GOLAND_JDK=/nix/store/...-jetbrains-jdk-21.0.9-b1163.86/lib/openjdk goland-remote-dev-server status

      # 这次能正常输出 STATUS，说明问题就在 JDK 路径层级上。
      # GOLAND_JDK = "${pkgs.jetbrains.jdk-no-jcef}";
      GOLAND_JDK = "${pkgs.jetbrains.jdk-no-jcef}/lib/openjdk";
    };
  };
}
