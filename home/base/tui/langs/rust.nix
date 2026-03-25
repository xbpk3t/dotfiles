{pkgs, ...}: {
  home.packages = with pkgs; [
    # TODO[2026-03-25](fenix): 之后评估一下是否要引入 fenix 作为rust工具链的 flake
    # https://mynixos.com/fenix
    # https://github.com/nix-community/fenix

    # TODO[2026-03-25](crane): 评估一下是否需要引入 crane
    # https://github.com/ipetkov/crane
    #- `crane` 很适合“用 Nix 构建 Rust 项目”。
    #- 但你当前仓库是系统配置仓库，不是 Rust 项目构建仓库；它没有可以直接发挥价值的主舞台。
    #- 如果你后续把自定义工具包、side project、CI 构建都收敛到这个仓库，`crane` 才可能变得更相关。
    #- 以当前状态看，它和仓库主链路偏离较大。

    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];
}
