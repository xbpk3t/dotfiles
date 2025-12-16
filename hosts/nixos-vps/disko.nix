{...}: let
  # 这个 disko.nix 是否必须？在什么情况下必须？何时非必须？对于VPS来说，是否可以移除？
  # disko.nix 不是 NixOS 必需文件；它是可选的“声明式分区/格式化方案”（依赖 disko 模块）。
  #- 何时“必须”用它：
  #  - 你想完全声明式重装/无人值守（nixos-anywhere, nixos-rebuild switch --flake 配合 disko, 或 CI/PXE/云镜像自动装机）。
  #  - 需要把磁盘分区、文件系统、挂载选项等纳入版本管理，确保同一配置在新盘/新实例上可一键复现。
  #- 何时“可以不用”：
  #  - 机器已手工分好区、文件系统稳定且你不打算自动重装；只想管理系统层配置。
  #  - 桌面/工作站场景（如你的 nixos-ws）常在首次安装时手动分区，后续就靠 hardware-configuration.nix 里的fileSystems 和 swapDevices 记录即可，不需要 disko。
  #- 对 VPS：
  #  - 如果你未来想“一条命令重建同规格 VPS”（含分区），保留disko.nix 很有价值，尤其云厂商重装/换实例时。
  #  - 如果该 VPS 磁盘布局简单且不打算自动化重装，完全可以移除 disko.nix，改成手动管理或只保留 fileSystems/swapDevices（用 hardware.nix 生成的传统方式）。
  #- 决策建议：
  #  - 需要可重复部署/自动装机 → 留 disko.nix。
  #  - 只做滚动维护、不折腾重装 → 移除也行，但记得在 host 里保留 fileSystems/swapDevices 描述现有分区。
  # VPS 提供的默认虚拟磁盘设备路径，可被上层覆写
  defaultDisk = "/dev/vda";
  # 用 mkDefault 便于在其他主机上重写磁盘设备名
  mkDiskDevice = device: device;
  # 各分区标签，便于通过 /dev/disk/by-partlabel 引用
  espLabel = "ESP";
  rootLabel = "NIXOS_ROOT";
  swapLabel = "NIXOS_SWAP";
  # 通用挂载参数：关闭 atime，降低写放大
  mountOptions = ["noatime" "nodiratime"];
in {
  disko.devices = {
    disk.vda = {
      # 定义整块虚拟磁盘的分区方案
      type = "disk";
      device = mkDiskDevice defaultDisk;
      content = {
        type = "gpt";
        partitions = {
          bios = {
            # 兼容 BIOS 的引导分区（1M，EF02）
            size = "1M";
            type = "EF02";
          };

          esp = {
            # UEFI 系统分区，挂载到 /boot/efi
            size = "512M";
            type = "EF00";
            label = espLabel;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = ["fmask=0077" "dmask=0077"];
            };
          };

          swap = {
            # 交换分区，便于小内存 VPS 使用
            size = "2G";
            type = "8200";
            label = swapLabel;
            content = {
              type = "swap";
            };
          };

          root = {
            # 根分区占用剩余空间，ext4 文件系统
            size = "100%";
            type = "8300";
            label = rootLabel;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = mountOptions;
            };
          };
        };
      };
    };
  };

  fileSystems."/" = {
    # 通过分区标签挂载根分区
    device = "/dev/disk/by-partlabel/${rootLabel}";
    fsType = "ext4";
    options = mountOptions;
  };

  fileSystems."/boot/efi" = {
    # UEFI 系统分区挂载点
    device = "/dev/disk/by-partlabel/${espLabel}";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    # 指定 swap 分区供系统启用
    {device = "/dev/disk/by-partlabel/${swapLabel}";}
  ];
}
