{pkgs, ...}: {
  home.packages = with pkgs; [
    # 磁盘健康/检测
    # https://mynixos.com/nixpkgs/package/smartmontools
    # smartctl（smartmontools）：读/写盘的 S.M.A.R.T. 数据，支持 SATA/USB/部分 NVMe，快速健康概览、离线/短测。
    # 智能信息：smartctl -a /dev/sdX
    # 快速短测：smartctl -t short /dev/sdX && smartctl -l selftest /dev/sdX
    smartmontools

    # nvme-cli：专为 NVMe，读取/操作 NVMe Log（smart-log、error-log）、固件下载、格式化等，信息比 smartctl 更全更准。
    # 三者是互补关系：smartctl/ nvme-cli 负责健康信息，badblocks 做面向介质的全盘扫描。
    # https://mynixos.com/nixpkgs/package/nvme-cli
    # NVMe 健康：nvme smart-log /dev/nvme0
    nvme-cli

    # badblocks（e2fsprogs 内）：逐扇区读写/只读扫描找坏块，时间长，适合深度体检或新盘出厂验证
    # https://mynixos.com/nixpkgs/package/e2fsprogs
    # 深度扫描（只读示例）：sudo badblocks -sv /dev/sdX（慎用写测，会清空数据）
    e2fsprogs
  ];
}
