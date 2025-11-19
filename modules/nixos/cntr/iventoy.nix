{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.services.iventoy;
  containerName = "iventoy";
in {
  # https://hub.docker.com/r/szabis/iventoy
  # https://github.com/garybowers/iventoy_docker
  # iVentoy（包括这个Docker镜像）在装机时确实需要通过LAN（有线网）来工作，因为它是一个基于PXE的网络启动工具，主要依赖局域网内的DHCP和TFTP服务来引导客户端从服务器上获取ISO镜像并启动安装。
  # 为什么必须插网线？
  #
  # PXE引导机制：iVentoy服务器（运行在Docker中）和目标机器（装机机）必须在同一个局域网（LAN）内。目标机通过网络卡（NIC）从iVentoy服务器请求引导文件和ISO数据。如果没有网线连接，目标机就无法接入LAN，也就无法PXE启动。
  # 没有WiFi支持：PXE标准主要针对有线网络（Ethernet），无线WiFi在BIOS/UEFI的PXE模式下支持有限或不稳定，尤其在装机初期（还没安装驱动）。如果你用WiFi适配器，它可能需要额外的驱动，但iVentoy的ISO挂载和数据传输仍需稳定的LAN连接。
  # ISO传输：你把ISO存到iVentoy服务器上，目标机通过网络“挂载”它作为虚拟光驱。如果断网（无网线），传输就会失败。
  # 简单来说，因为在装机时，还没有wifi，所以必须要插着网线走LAN，才能从另一台机器上拿到这个iventoy上存着的iso。

  options.modules.services.iventoy = {
    enable = mkEnableOption "iVentoy PXE service (container)";

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra attributes merged into the container definition.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.${containerName} = mkMerge [
      {
        autoStart = false;
        image = "szabis/iventoy:latest";
        environment.AUTO_START_PXE = "true";
        volumes = [
          "/path/to/data:/opt/iventoy/data:rw"
          "/path/to/iso:/opt/iventoy/iso:rw"
          "/path/to/log:/opt/iventoy/log:rw"
          "/path/to/user:/opt/iventoy/user:rw"
        ];
        ports = [
          "67:67/udp"
          "69:69/udp"
          "10809:10809/tcp"
          "16000:16000/tcp"
          "26000:26000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network=host"
          "--privileged"
        ];
      }
      cfg.settings
    ];
  };
}
