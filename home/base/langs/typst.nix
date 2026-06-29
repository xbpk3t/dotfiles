{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      typst

      # why: 用来替代 typstfmt
      typstyle
    ]
    ++ (with pkgs.typstPackages; [
      # https://mynixos.com/nixpkgs/packages/typstPackages
      # what: slides framework with themes and overlays
      touying
      # what: minimalist slides framework
      polylux
      # what: drawing/diagram library inspired by TikZ/Processing
      cetz
      # what: node+arrow diagrams (commutative diagrams/flowcharts)
      fletcher
      # what: algorithm typesetting (simple, compact)
      # https://github.com/platformer/typst-algorithms
      algo
      # what: algorithmicx-style pseudocode
      algorithmic
      # what: GitHub-style admonitions/alerts
      note-me

      # https://typst.app/universe/package/herodot/
      # 貌似比  timeliney/zeitline 这两个 timeline 组件好用
      herodot
    ]);
}
