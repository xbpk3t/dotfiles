{pkgs, ...}: {
  # Nix/NixOS 开发与调试常用 CLI
  environment.systemPackages = with pkgs; [
    # === 代码检查与格式化 ===
    # 发现 nix 里未使用的变量/绑定
    deadnix
    statix # nix 风格与常见陷阱检查
    alejandra # nix 代码格式化

    # === nixpkgs开发 ===
    # nix-unit     # 运行 nix 单元测试

    # === nix 单元测试框架 ===
    namaka
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
}
