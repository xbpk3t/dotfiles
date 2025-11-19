{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.qinglong;
  containerName = "qinglong";
  stateDir = "/var/lib/${containerName}";
in {
  #  https://linux.do/t/topic/483523
  #  https://linux.do/t/topic/32503/75

  #  shufflewzc/faker2：京东脚本库助力池版，提供强大的京东自动化功能。
  #  shufflewzc/faker3：京东脚本库内部互助版，适合团队或互助小组使用。
  #  6dylan6/jdpro：另一个京东脚本库，与faker形成互补，持续更新，适用于不同需求。
  #  leafTheFish/DeathNote：提供多个APP签到类脚本，JS加密保护，安全可靠。
  #  smallfawn/QLScriptPublic：包含近百个APP、小程序签到类脚本，部分经过JS加密处理。
  #  lzwme/ql-scripts：个人维护的基于需求的自用青龙脚本集，以TypeScript编写，实用性强。

  #  https://qinglong.online/en/guide/getting-started/installation-guide/docker-compose
  #  https://github.com/Sitoi/dailycheckin
  #  https://qd-today.github.io/qd/
  #  https://github.com/qd-today/qd
  #  https://github.com/einverne/dockerfile/tree/master/qiandao

  options.modules.services.qinglong = {
    enable = mkEnableOption "QingLong automation suite (Docker)";

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Freeform attributes merged into the OCI container definition.
        Useful for overriding ports, volumes, or other container options.
      '';
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "QingLong");
      default = null;
      description = "Expose QingLong via the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d ${stateDir} 0750 root root -"
      ];

      virtualisation.oci-containers.containers.${containerName} = mkMerge [
        {
          autoStart = false;
          image = "whyour/qinglong:latest";
          environment = {
            "QlBaseUrl" = "/";
          };
          volumes = [
            "${stateDir}:/ql/data:rw"
            #            "/home/luck/Desktop/dotfiles/manifests/docker/qinglong/data:/ql/data:rw"
          ];
          ports = [
            "5700:5700/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            #            "--network-alias=web"
            #            "--network=qinglong_default"
          ];
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.qinglong";
        ingress = cfg.ingress;
      })
    )
  ];
}
