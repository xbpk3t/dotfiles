{ pkgs, config, ... }:
{
  # Docker LSP 包，供 zed/helix 等 IDE 使用
  modules.langs.lsp.packages = with pkgs; [
    dockerfile-language-server
  ];

  # Colima 本身负责创建和管理 docker context，这里只负责声明式启用默认 profile。
  programs.docker-cli = {
    enable = true;

    #  - aliases — 如果你经常手敲 docker 命令，加几个常用的能省不少时间；如果只是偶尔用，意义不大。纯粹看个人习惯。
    #  - detachKeys — 默认 ctrl-p,ctrl-q 已经够用，除非你遇到快捷键冲突（比如 tmux 里），否则不需要改。
    #  - credHelpers — 你已经用了 credsStore = "osxkeychain"，它会统一处理所有 registry 的凭证。credHelpers 只在你需要按 registry 用不同 helper 时才需要（比如 AWS ECR 用 ecr-login），否则多余。
    settings = {
      # Colima 模块（services.colima）在 active profile 存在时，
      # 会自动设置 programs.docker-cli.settings.currentContext = "colima"。
      # 此处无需重复声明。

      # 如果你有其他全局配置，也可以加在这里
      # 例如：
      features = {
        # 注意应该是字符串，否则会报错 json: cannot unmarshal bool into Go struct field ConfigFile.features of type string
        buildkit = "true";
      };

      # 这里用 credsStore 代替 auths
      # macOS 上推荐用 keychain
      credsStore = "osxkeychain";
    };
  };

  home.packages =
    with pkgs;
    [
      docker
      # 否则会报 osxkeychain not found
      docker-credential-helpers
    ]
    ++ [
      # 日常 CLI / TUI 操作
      ctop
    ]
    ++ [
      # 镜像分析 / 瘦身
      dive
      docker-slim
    ]
    ++ [
      # Dockerfile / 供应链安全

      hadolint

      # Image 安全漏洞扫描
      trivy
      syft
      grype

      # Docker Scout：如果你更想走官方路线，Scout 已经把 SBOM、CVE、recommendations、policy 等都收进 docker scout 命令体系了
      # docker scout: 当前 nixpkgs 暂无独立 docker-scout 包，先不添加。
    ];

  home = {
    shellAliases = {
      runlike = "uvx runlike";
      autocompose = "uvx --from docker-autocompose autocompose";
    };

    sessionVariables = {
      DOCKER_HUB_TOKEN = "$(cat ${config.sops.secrets.DOCKER_HUB_TOKEN.path})";
    };
  };

}
