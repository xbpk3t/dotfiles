{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/typst
    # https://github.com/ItsEthra/typst-live
    typst

    # https://mynixos.com/nixpkgs/package/typstyle
    # why: 用来替代 typstfmt
    typstyle

    # https://mynixos.com/nixpkgs/packages/typstPackages
    # what: slides framework with themes and overlays; url: https://mynixos.com/nixpkgs/package/typstPackages.touying
    typstPackages.touying
    # what: minimalist slides framework; url: https://mynixos.com/nixpkgs/package/typstPackages.polylux
    typstPackages.polylux
    # what: drawing/diagram library inspired by TikZ/Processing; url: https://mynixos.com/nixpkgs/package/typstPackages.cetz
    typstPackages.cetz
    # what: node+arrow diagrams (commutative diagrams/flowcharts); url: https://mynixos.com/nixpkgs/package/typstPackages.fletcher
    typstPackages.fletcher
    # what: algorithm typesetting (simple, compact); url: https://mynixos.com/nixpkgs/package/typstPackages.algo
    # https://github.com/platformer/typst-algorithms
    typstPackages.algo
    # what: algorithmicx-style pseudocode; url: https://mynixos.com/nixpkgs/package/typstPackages.algorithmic
    typstPackages.algorithmic
    # what: GitHub-style admonitions/alerts; url: https://mynixos.com/nixpkgs/package/typstPackages.note-me
    typstPackages.note-me

    # https://mynixos.com/nixpkgs/package/typstPackages.herodot
    # https://typst.app/universe/package/herodot/
    # 貌似比  timeliney/zeitline 这两个 timeline 组件好用
    typstPackages.herodot
  ];
}
