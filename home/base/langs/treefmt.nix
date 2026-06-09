{
  lib,
  pkgs,
  mylib,
  ...
}:
{
  home.packages =
    (with pkgs; [
      # ── Hook runner / meta formatter ─────────────────────────
      prek
      treefmt

      # ── Formatters (used by treefmt) ───────────────────────────
      nixfmt
      taplo
      # kdlfmt 的 pre-commit 仍然需要bin才能使用
      # tags(desc): 代码质量 > 格式化 > KDL
      kdlfmt
      stylua
      shfmt
      # terraform: installed via home/base/devops/tf.nix
      # hclfmt:    included in terraform package

      # ── Linters ────────────────────────────────────────────────
      actionlint
      hadolint
      golangci-lint
      ruff
      statix
      deadnix
      # tags(desc): 代码质量 > 格式化 > Nix
      # nix 代码格式化
      # alejandra

      gitlint
      commitizen
      prettier

      # 代码质量和分析
      # tags(desc): 代码质量 > Shell静态检查 > Lint
      shellcheck
      # tags(desc): 代码质量 > 拼写检查 > Lint
      typos
      # tags(desc): 代码质量 > YAML规范 > Lint
      yamllint
      # tags(desc): 代码质量 > Markdown规范 > Lint
      markdownlint-cli
      # tags(desc): 代码质量 > CSS规范 > 前端
      stylelint

      # ── Pre-commit / prek remote-hook system alternatives ─────
      # pre-commit-ci-config、pre-commit-terraform wrapper、postcss-scss 暂无直接 nixpkgs attr。
      python3Packages.pre-commit-hooks
      buf
      terraform-docs
      tflint
    ])
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Darwin 上 d2 的依赖链会拉到 mesa-libgbm -> libdrm，触发
      # "Refusing to evaluate package 'libdrm' on aarch64-darwin"。
      pkgs.d2
    ];

  # Deploy linter configs globally from .github/linters/
  home.file.".config/linters" = {
    source = mylib.relativeToRoot ".github/linters";
    recursive = true;
  };
}
