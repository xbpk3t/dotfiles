{
  pkgs,
  mylib,
  ...
}:
{
  home.packages = with pkgs; [
    # ── Hook runner / meta formatter ─────────────────────────
    treefmt

    # ── Formatters (used by treefmt) ───────────────────────────

    taplo
    # kdlfmt 的 pre-commit 仍然需要bin才能使用
    # tags(desc): 代码质量 > 格式化 > KDL
    kdlfmt

    # terraform: installed via home/base/devops/tf.nix
    # hclfmt:    included in terraform package

    ruff

    # tags(desc): 代码质量 > 拼写检查 > Lint
    typos
    # tags(desc): 代码质量 > YAML规范 > Lint
    yamllint
    # tags(desc): 代码质量 > Markdown规范 > Lint
  ];

  # Deploy linter configs globally from .github/linters/
  home.file.".config/linters" = {
    source = mylib.relativeToRoot ".github/linters";
    recursive = true;
  };
}
