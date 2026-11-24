{
  hostMeta,
  mylib,
  ...
}:
let
  # 内存事实唯一来源是 hosts/<...>/meta.nix 的 hardware.memGiB；
  # hardware 缺失时回落 null（保守的 25%）。
  memGiB = hostMeta.hardware.memGiB or null;
  zramProfile = mylib.vpsSysctl.mkZramProfile { inherit memGiB; };
in
{
  # Enable in-memory compressed devices and swap space provided by the zram kernel module.
  # By enable this, we can store more data in memory instead of fallback to disk-based swap devices directly,
  # and thus improve I/O performance when we have a lot of memory.
  #
  #   https://www.kernel.org/doc/Documentation/blockdev/zram.txt
  zramSwap = {
    enable = true;

    # one of "lzo", "lz4", "zstd"
    # [2025-10-09] 内存这种热数据应用lz4这种高吞吐（CPU开小弟）、低压缩比的压缩算法
    algorithm = "lz4";

    # Priority of the zram swap devices.
    # It should be a number higher than the priority of your disk-based swap devices
    # (so that the system will fill the zram swap devices before falling back to disk swap).
    priority = 5;

    # 设备大小 = min(RAM × memoryPercent, memoryMax)：
    # - 小内存 VPS（≤8G）用 50%，4G 机器约 2G 压缩内存盘
    # - 大内存机器用 25%，并用 memoryMax=4G 封顶
    # - 没有 hardware profile 时保守用 25%
    # 注意：这是“未压缩上限”，实际占用取决于 lz4 压缩比（看 zramctl 的 DATA）。
    inherit (zramProfile) memoryPercent memoryMax;
  };
}
