{
  inputs,
  mylib,
  myvars,
  lib,
  ...
} @ args: let
  macosSystemArgs =
    args
    // {
      inherit lib;
    };

  name = "macos-ws";
  # ssh-host = "100.115.38.12";
  ssh-host = "127.0.0.1";

  genSpecialArgs = system: let
    customPkgsOverlay = import (mylib.relativeToRoot "pkgs/overlay.nix");
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
      overlays = [
        customPkgsOverlay
      ];
    };
  in {
    inherit
      inputs
      mylib
      myvars
      pkgs
      ;

    # use unstable branch for some packages to get the latest updates
    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        customPkgsOverlay
      ];
    };
  };

  modules = {
    darwin-modules =
      [
        inputs.sops-nix.darwinModules.sops
      ]
      ++ map mylib.relativeToRoot [
        "secrets/default.nix"
        "modules/darwin"
        "hosts/${name}/default.nix"
      ];
    home-modules = map mylib.relativeToRoot [
      "secrets/default.nix"
      "hosts/${name}/home.nix"
      "home/base"
      "home/darwin"
    ];
  };
  systemArgs = macosSystemArgs // modules;
  darwinConfig = mylib.macosSystem (
    systemArgs
    // {
      genSpecialArgs = genSpecialArgs;
      system = "aarch64-darwin";
    }
  );
  deployNode = let
    deployLib = inputs."deploy-rs".lib."aarch64-darwin";
    sshUser = myvars.username;
  in {
    # What：部署目标地址（主机名/SSH alias）。
    # Why：保持与 inventory/主机名一致，便于统一管理。
    # 注意这里本应是 hostname = name，但是
    hostname = ssh-host;
    # What：SSH 用户名。
    # Why：darwin 通常使用本地用户名进行远程连接。
    inherit sshUser;
    # What：是否在远端构建。
    # Why：darwin 的 system closure 必须在 darwin 端构建/激活。
    remoteBuild = true;
    profiles.system = {
      # What：远端激活该 profile 的用户。
      # Why：需要 root 权限写入系统级配置。
      user = "root";
      # What：nix-darwin 的激活路径。
      # Why：nix-darwin 的 system closure 内置 ./activate，需要用 activate.custom 指定入口。
      path = deployLib.activate.custom darwinConfig.system "./activate";
    };
  };
in {
  darwinConfigurations.${name} = darwinConfig;
  deploy.nodes.${name} = deployNode;
}
