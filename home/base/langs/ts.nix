{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # 分类1：Node.js/TypeScript 核心工具链
      # Node.js 生态
      # tags(desc): 核心工具链 > JavaScript运行时 > Node生态
      nodejs

      # tags(desc): 包管理 > Node生态 > 性能优先
      pnpm

      # [2026-01-21] rebuild error, hash mismatch, so comment it
      # tags(desc): 执行器 > TypeScript运行 > Node生态
      tsx

      # tags(desc): 核心工具链 > 语言编译器 > TypeScript
      typescript
      # error: 'ts-node' was removed because it is unmaintained, and since NodeJS 22.6.0+, experimental TypeScript support is built-in to NodeJS.
      # ts-node
      # tags(desc): 语言服务 > YAML > LSP
      yaml-language-server
    ]
    ++ [
      # 分类2：依赖治理与前端质量

      # Web 开发
      # tailwindcss
      # tailwindcss-language-server
      # tags(desc): 依赖治理 > 版本审计 > npm生态
      npm-check
      # tags(desc): 依赖治理 > 版本升级 > npm生态
      npm-check-updates

      # tags(desc): 代码质量 > CSS规范 > 前端
      stylelint

      # tags(desc): 代码质量 > 语法检查 > JavaScript/TypeScript
      eslint
      oxlint
      # tags(desc): 代码质量 > 格式化 > JavaScript/TypeScript
      prettier
    ];

  # 注意 pnpm 跟 npm 的配置文件不同。而 npm本身是支持 hm配置的，所以采用这个方式配置。
  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Preferences/pnpm/rc".source = ./pnpmrc;
  };

  xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
    "pnpm/rc".source = ./pnpmrc;
  };

  # $HOME/.config/.bunfig.toml
  # [2026-01-19] 安装 OMO 需要先安装bun
  programs.bun = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      smol = true;
      telemetry = false;
      test = {
        coverage = true;
        coverageThreshold = 0.9;
      };
      install.lockfile = {
        # Whether to generate a non-Bun lockfile alongside bun.lock. (A bun.lock will always be created.) Currently "yarn" is the only supported value.
        print = "yarn";
      };
    };
  };
}
