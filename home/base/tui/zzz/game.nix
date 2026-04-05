{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/vitetris
    # https://github.com/vicgeralds/vitetris
    # 俄罗斯方块
    # [2026-04-04] report: zsh: trace trap
    vitetris
  ];
}
