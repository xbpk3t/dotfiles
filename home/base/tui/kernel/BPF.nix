{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/bpftrace
    # bpftrace probe 列举，仅 linux 内核追踪场景
    # sudo bpftrace -l
    # bpftrace 动态追踪，特定场景但非日常
    # sudo bpftrace '{{.PROG}}'
    #

    # https://mynixos.com/nixpkgs/package/bpftools
    # bpftool 查看 BPF 程序，排查 BPF 相关问题时有用
    # sudo bpftool prog show
    # bpftool map，同上场景
    # sudo bpftool map show
    # bpftool 查看网络 attach 点，网络 BPF 调试时有用
    # sudo bpftool net
  ];
}
