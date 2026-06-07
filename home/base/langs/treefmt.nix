{
  pkgs,
  mylib,
  ...
}:
{
  home.packages = with pkgs; [
    # ── Meta formatter ─────────────────────────────────────────
    treefmt

    # ── Formatters (used by treefmt) ───────────────────────────
    nixfmt
    taplo
    # https://mynixos.com/nixpkgs/package/kdlfmt
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

    # https://mynixos.com/nixpkgs/package/api-linter
    # https://mynixos.com/nixpkgs/package/dotenv-linter
    # https://mynixos.com/nixpkgs/package/gitlab-ci-linter
  ];

  # Deploy linter configs globally from .github/linters/
  home.file.".config/linters" = {
    source = mylib.relativeToRoot ".github/linters";
    recursive = true;
  };
}
