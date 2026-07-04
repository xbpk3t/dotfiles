{
  inputs,
  pkgs,
  ...
}:
{
  # Nix LSP 包，供 zed/helix 等 IDE 使用
  modules.langs.lsp.packages = with pkgs; [
    nil
    nixd
  ];

  # Nix/NixOS 开发与调试常用 CLI
  home.packages =
    with pkgs;
    [
      # === Nix 打包工具 ===
      noogle-search
      nvfetcher
      crane

      nurl
    ]
    ++ [
      # 分类2：代码质量与测试

      # === 代码检查与格式化 ===
      # 发现 nix 里未使用的变量/绑定
      # tags(desc): 代码质量 > 格式化 > Nix
      nixfmt
      # tags(desc): 代码质量 > 规则检查 > Nix
      statix # nix 风格与常见陷阱检查

      # === nixpkgs开发 ===
      # 两套 Nix 单元测试工具都保留，便于分别试用/迁移。
      # tags(desc): 测试框架 > 单元测试 > Nix表达式
      inputs.nixt.packages.${pkgs.stdenv.hostPlatform.system}.default
      # tags(desc): 测试框架 > 单元测试 > Nix表达式
      inputs.nix-unit.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ [
      # 分类3：依赖与构建分析

      # === 依赖/构建分析 ===
      # 从 derivation 提取源码/补丁等
      # tags(desc): 构建分析 > derivation检查 > 源提取
      nixtract
      # 检查 hydra 依赖/评估情况
      # tags(desc): 构建分析 > CI评估 > Hydra
      hydra-check
      # 解析 store path 依赖树
      # tags(desc): 依赖分析 > store路径 > 关系图
      nix-melt
      # 树状查看依赖（替代 nix-store --query --requisites）
      # tags(desc): 依赖分析 > 依赖树 > store查询
      nix-tree
    ];

  programs.zsh.shellAliases = {
    # noogle-search 是 nixpkgs 中的实际可执行文件名；补一个更直观的入口。
    noogle = "noogle-search";
  };

  # nix-init: Nix 包起稿工具
  programs.nix-init = {
    enable = true;
  };
}
