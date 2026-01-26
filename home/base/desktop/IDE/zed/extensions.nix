{
  # MAYBE[2026-01-18]: 判断是否要
  #
  #
  #
  # [The possibility to add custom language servers in configuration only · zed-industries/zed · Discussion #24092 · GitHub](https://github.com/zed-industries/zed/discussions/24092)

  # https://github.com/zed-extensions/nix
  "nix" = true;
  "rst" = true;

  "basher" = true;
  # https://github.com/biomejs/biome-zed
  "biome" = true;
  "cargotoml" = true;
  "catppuccin-icons" = true;
  "git-firefly" = true;
  "marksman" = true;
  "snippets" = true;
  "toml" = true;
  "typos" = true;
  "zig" = true;

  # https://github.com/zed-extensions/golangci-lint
  # https://mynixos.com/nixpkgs/package/golangci-lint-langserver
  "golangci-lint" = true;

  # LSP for justfile
  # https://github.com/jackTabsCode/zed-just
  "justfile" = true;

  # https://github.com/zed-extensions/nu
  "nu" = true;

  # https://github.com/bajrangCoder/zed-scss
  "scss" = true;

  "svelte" = true;
  # https://github.com/zed-extensions/lua
  "lua" = true;
  # https://github.com/bajrangCoder/zed-ini
  "ini" = true;

  "astro" = true;
  "docker-compose" = true;
  "html" = true;
  "vue" = true;

  # https://github.com/zed-extensions/dockerfile
  "dockerfile" = true;

  "make" = true;
  # https://github.com/zed-extensions/sql
  "sql" = true;

  # https://github.com/zed-extensions/terraform
  "terraform" = true;

  # https://github.com/zed-industries/extensions/issues/523
  # https://zed.dev/extensions/comment
  # https://github.com/thedadams/zed-comment
  # https://github.com/stsewd/tree-sitter-comment comment插件就是基于该LSP实现的
  # 可以通过 theme_overrides 来custom 这些comments style，但是没必要
  # 注意该插件不支持自定义 TODO Tag (比如说我需要的 PLAN)
  "comment" = true;

  # https://github.com/zed-extensions/log
  "log" = true;

  # https://github.com/oxc-project/oxc-zed
  #
  # [2026-01-22] 会卡在 installing extensions 所以注释掉
  #
  # 用于 JS/TS 的 lint 与格式化
  # 相较 ESLint 快很多（50–100x 这个量级）
  "oxc" = true;

  # https://github.com/gabeins/zed-mermaid
  "mermaid" = true;

  # https://github.com/gabeins/zed-plantuml
  "plantuml" = true;

  # "catppuccin"
  # "material-icon-theme"
  # "wakatime"
  #
  #
}
