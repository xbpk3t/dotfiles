{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://github.com/mermaid-js/mermaid-cli
    # https://mynixos.com/nixpkgs/package/mermaid-cli
    # mmdc
    mermaid-cli

    # https://mynixos.com/nixpkgs/package/plantuml
    plantuml
    # https://mynixos.com/nixpkgs/package/plantuml-c4
    # C4-PlantUML 的 !include 宏、sprite 库、C4 的组件语法
    # plantuml-c4 的价值主要在“要画 C4 模型并复用它的库/图标/皮肤”时（比如 C4Context / Container 那套）
    # conflict with plantuml:
    #        > pkgs.buildEnv error: two given paths contain a conflicting subpath:
    #       >   `/nix/store/7gj2iizhm9xibzfrbqpiv0pilsdwlgxk-plantuml-c4-2.10.0/bin/plantuml' and
    #       >   `/nix/store/3r2vp3khzv7saq69pcaabadx42293k6l-plantuml-1.2026.1/bin/plantuml'
    #       > hint: this may be caused by two different versions of the same package in buildEnv's `paths` parameter
    # plantuml-c4

    # https://mynixos.com/nixpkgs/package/d2
    d2

    # https://mynixos.com/nixpkgs/package/pikchr
    pikchr

    # https://mynixos.com/nixpkgs/package/excalidraw_export
    # https://github.com/Timmmm/excalidraw_export
    # https://www.npmjs.com/package/excalidraw_export
    # https://github.com/Automattic/node-canvas
    # https://github.com/Automattic/node-canvas/issues/788
    # excalidraw_export

    # https://mynixos.com/nixpkgs/package/drawio-headless
    # drawio-headless

    # https://github.com/yuzutech/kroki

    # https://www.eraser.io/ ???
  ];
}
