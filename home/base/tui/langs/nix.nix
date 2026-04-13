{
  inputs,
  pkgs,
  ...
}: {
  # Nix/NixOS 开发与调试常用 CLI
  home.packages = with pkgs; [
    # https://github.com/nix-community/noogle
    # https://noogle.dev/
    # nix search nixpkgs noogle
    # what: nixpkgs 里的 Noogle 终端搜索前端，用来查 Nix API / lib / builtins 函数。
    # why: 这类检索需求属于开发型主机共享能力，适合放在 langs 层，而不是 mac 专属或 core 基础层。
    noogle-search

    ###### nixpkgs 打包相关 ##########
    # https://mynixos.com/nixpkgs/package/nurl
    nurl

    # https://github.com/berberman/nvfetcher
    # nvfetcher -- -c nvfetcher.toml -o pkgs/_sources
    # 统一维护 repo 内自定义 source 的更新元数据。
    # 注意：它不是 builder，本质上是 source update generator。
    nvfetcher

    # === 代码检查与格式化 ===
    # 发现 nix 里未使用的变量/绑定
    nixfmt
    deadnix
    statix # nix 风格与常见陷阱检查
    alejandra # nix 代码格式化

    # === nixpkgs开发 ===
    # 两套 Nix 单元测试工具都保留，便于分别试用/迁移。
    inputs.nixt.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nix-unit.packages.${pkgs.stdenv.hostPlatform.system}.default

    # 交互式生成 nix 包模板
    # nix-init

    # === 依赖/构建分析 ===
    # 从 derivation 提取源码/补丁等
    nixtract
    # 检查 hydra 依赖/评估情况
    hydra-check
    # 解析 store path 依赖树
    nix-melt
    # 树状查看依赖（替代 nix-store --query --requisites）
    nix-tree
  ];

  # https://mynixos.com/home-manager/options/programs.nix-init
  # https://mynixos.com/nixpkgs/package/nix-init
  # nix-init 是基于nurl实现的
  # nix-init 和 nurl 都可以用来给“没有nixpkgs”的pkg手动打包。但是
  programs.nix-init = {
    enable = true;
  };

  programs.zsh.shellAliases = {
    # noogle-search 是 nixpkgs 中的实际可执行文件名；补一个更直观的入口。
    noogle = "noogle-search";
  };
}
