{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    lib.optionals stdenv.isLinux [
      # bpftool 查看 BPF 程序，排查 BPF 相关问题时有用
      # sudo bpftool prog show
      # bpftool map，同上场景
      # sudo bpftool map show
      # bpftool 查看网络 attach 点，网络 BPF 调试时有用
      # sudo bpftool net
      bpftools
    ];
}
