{
  inputs,
  mylib,
  lib,
  mkSpecialArgs,
  ...
} @ args: let
  macosSystemArgs =
    args
    // {
      inherit lib;
    };

  name = "macos-ws";
  node = mylib.inventory."macos-ws".${name};

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
  systemArgs =
    macosSystemArgs
    // modules
    // {
      specialArgs = mkSpecialArgs "aarch64-darwin" node;
    };
  darwinConfig = mylib.macosSystem (
    systemArgs
    // {
      system = "aarch64-darwin";
    }
  );
  deployNode = let
    deployLib = inputs."deploy-rs".lib."aarch64-darwin";
    sshUser = node.ssh.user;
  in {
    # What：部署目标地址（主机名/SSH alias）。
    # Why：保持与 inventory/主机名一致，便于统一管理。
    hostname = node.primaryIp;
    # What：SSH 用户名。
    # Why：darwin 通常使用本地用户名进行远程连接。
    inherit sshUser;
    # What：是否在远端构建。
    # Why：darwin 的 system closure 必须在 darwin 端构建/激活。
    remoteBuild = true;
    # What：关闭 deploy-rs 的 magic rollback。
    # Why：本机 localhost 上的 nix-darwin 激活已成功，但 confirmation waiter 偶发超时，
    # 会导致 deploy-rs 误判失败并回滚；对本机部署保留这层保护收益不高。
    magicRollback = false;
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
