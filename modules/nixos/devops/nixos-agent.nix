{
  lib,
  mylib,
  pkgs,
  userMeta,
  timeMeta,
  editorMeta,
  stateVersion,
  inputs,
  globals,
  ...
}:
{
  containers.nixos-agent = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.233.0.1";
    localAddress = "10.233.0.2";
    specialArgs = {
      inherit mylib globals;
      inherit userMeta timeMeta stateVersion;
      mail = userMeta.mail or null;
    };
    config = {
      # 容器使用宿主机（nixos-vps）的 pkgs → nixpkgs-stable
      # allowUnfree + overlay 已由宿主机 pkgs 内置，不设 config/overlays 避免断言冲突
      nixpkgs.pkgs = pkgs;
      imports = [
        inputs.sops-nix.nixosModules.sops
        (mylib.relativeToRoot "modules/nixos/kernel")
        (mylib.relativeToRoot "modules/nixos/devops/container.nix")
        (mylib.relativeToRoot "modules/nixos/kernel/fhs.nix")
        (mylib.relativeToRoot "secrets/default.nix")
        inputs.home-manager.nixosModules.home-manager
      ];

      # ── 容器 NixOS 配置 ──

      networking.hostName = lib.mkDefault "nixos-agent";

      # boot.isContainer / networking.useDHCP = false 由 nixos-containers.nix 的 extraConfig 自动注入
      # [2026-05-25] 容器 DNS：boot.isContainer 环境下 resolvconf 会生成 127.0.0.53
      # （systemd-resolved stub），但容器内 resolved 已禁用且网络命名空间隔离无法
      # 访问宿主机 stub。关闭 resolvconf，直接硬写 resolv.conf。
      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".text = lib.mkForce ''
        nameserver 119.29.29.29
        nameserver 223.5.5.5
        options edns0 trust-ad
      '';

      # 容器首次激活时 /home/luck 可能未创建（user-group.nix 的 isNormalUser 和
      # home-manager 激活脚本的时序不确定），导致 sops-nix 写 ~/.config/systemd 失败。
      # activationScript 在 NixOS switch 期间同步执行（deps 保证在 users 创建后），
      # 比 systemd-tmpfiles（异步 service）更可靠。
      # 注意：chown 不能 -R，sops age keys.txt 通过 bind mount 挂载为只读。
      system.activationScripts.ensureHomeDir = {
        text = ''
          chown luck:users /home/luck
          mkdir -p /home/luck/.config/systemd
          chown luck:users /home/luck/.config /home/luck/.config/systemd
        '';
        deps = [
          "users"
          "groups"
        ];
      };

      system.stateVersion = lib.mkDefault stateVersion;

      # ── home-manager 用户配置 ──

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = null;
        extraSpecialArgs = {
          inherit inputs mylib globals;
          inherit
            userMeta
            timeMeta
            editorMeta
            stateVersion
            ;
          mail = userMeta.mail or null;
        };
        users.luck.imports =
          map mylib.relativeToRoot [
            "secrets/default.nix"
            "home/core"
            "home/base"
          ]
          ++ [
            inputs.nix-index-database.homeModules.default
            inputs.sops-nix.homeManagerModules.sops
            # Agent 容器只包含 AI 工具链，不含任何桌面/IDE/图形组件
            {
              modules = {
                AI = {
                  claude = {
                    enable = true;
                    permissionMode = "yolo";
                  };
                  skills.enable = true;
                  cc-connect.enable = true;
                };
                infra = {
                  nh.enable = true;
                  networking.enable = true;
                };
              };
            }
          ];
      };
    };
  };
}
