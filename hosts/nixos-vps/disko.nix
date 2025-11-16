{lib, ...}: let
  defaultDisk = "/dev/vda";
  mkDiskDevice = device: lib.mkDefault device;
  espLabel = "ESP";
  rootLabel = "NIXOS_ROOT";
  swapLabel = "NIXOS_SWAP";
  mountOptions = ["noatime" "nodiratime"];
in {
  disko.devices = {
    disk.vda = {
      type = "disk";
      device = mkDiskDevice defaultDisk;
      content = {
        type = "gpt";
        partitions = {
          bios = {
            size = "1M";
            type = "EF02";
          };

          esp = {
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
            size = "2G";
            type = "8200";
            label = swapLabel;
            content = {
              type = "swap";
            };
          };

          root = {
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
    device = "/dev/disk/by-partlabel/${rootLabel}";
    fsType = "ext4";
    options = mountOptions;
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-partlabel/${espLabel}";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/disk/by-partlabel/${swapLabel}";}
  ];
}
