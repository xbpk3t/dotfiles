{pkgs, ...}: {
  # Colima 本身负责创建和管理 docker context，这里只负责声明式启用默认 profile。
  # https://mynixos.com/home-manager/options/programs.docker-cli
  programs.docker-cli = {
    enable = true;

    #  - aliases — 如果你经常手敲 docker 命令，加几个常用的能省不少时间；如果只是偶尔用，意义不大。纯粹看个人习惯。
    #  - detachKeys — 默认 ctrl-p,ctrl-q 已经够用，除非你遇到快捷键冲突（比如 tmux 里），否则不需要改。
    #  - credHelpers — 你已经用了 credsStore = "osxkeychain"，它会统一处理所有 registry 的凭证。credHelpers 只在你需要按 registry 用不同 helper 时才需要（比如 AWS ECR 用 ecr-login），否则多余。
    settings = {
      # 保持 currentContext 为 colima（Colima 启动时会自动设置，但声明式更保险）
      currentContext = "colima";

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

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/docker
    docker

    # https://mynixos.com/nixpkgs/package/docker-credential-helpers
    # 否则会报 osxkeychain not found
    docker-credential-helpers
  ];
}
