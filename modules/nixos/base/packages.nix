{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # version control
    git
    gitMinimal # 确保 Git 在构建环境中可用

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    tcpdump # network sniffer
    lsof # list open files

    # ebpf related tools
    # https://github.com/bpftrace/bpftrace
    bpftrace # powerful tracing tool
    bpftop # monitor BPF programs
    bpfmon # BPF based visual packet rate monitor

    # system monitoring
    sysstat
    iotop-c
    iftop
    btop
    nmon
    sysbench
    moreutils #https://mynixos.com/nixpkgs/package/moreutils #ts,...
    # system tools
    psmisc # killall/pstree/prtstat/fuser/...
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
    hdparm # for disk performance, command
    dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
    parted

    # https://github.com/ifd3f/caligula
    # Better dd (used to make UFEI Boot)
    caligula
  ];

  # BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more
  # https://github.com/iovisor/bcc
  programs.bcc.enable = true;
}
