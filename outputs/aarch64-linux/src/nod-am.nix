{
  inputs,
  mylib,
  ...
}:
let
  name = "nod-am";
  # host 元数据来自 inventory（分组 nod-am，节点 nod-am）
  node = mylib.inventory."nod-am".${name};

  # aarch64-linux 专用 pkgs：叠加 nix-on-droid overlay（proot-static 等预编译产物）
  # 参考 upstream wiki「Remote deploy with deploy-rs」的 pkgsFor
  pkgsForAndroid = import inputs.nixpkgs {
    system = "aarch64-linux";
    config = {
      allowUnfree = true;
      allowBroken = false;
      overlays = [
        inputs.nix-on-droid.overlays.default
      ];
    };
  };

  # nix-on-droid 配置（proot 用户态）
  # 注意：uid/gid 必须显式指定（deploy-rs 远程部署会生成错误 uid，见 issue #94）
  # 值来自设备上 `id nix-on-droid`，填在 inventory 里
  nodConfig = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs = pkgsForAndroid;
    modules = [
      (mylib.relativeToRoot "hosts/nod-am/default.nix")
      {
        # 从 inventory 读取真实 uid/gid，避免远程部署后用户 id 错乱
        user.uid = node.user.uid;
        user.gid = node.user.gid;
      }
    ];
  };

  # deploy-rs 激活 helper（upstream wiki 正宗写法）
  activateNixOnDroid =
    configuration:
    inputs.deploy-rs.lib.aarch64-linux.activate.custom configuration.activationPackage "${configuration.activationPackage}/activate";

  # deploy-rs 节点：从 Mac 通过 tailscale IP push 到手机
  # 手机端 NOD 内跑 userspace tailscale，注册到同一 tailnet
  deployNode = {
    hostname = node.tailscale.ip;
    profiles.system = {
      sshUser = node.ssh.user;
      user = node.ssh.user;
      magicRollback = true;
      sshOpts = [
        "-p"
        (toString node.ssh.port)
      ];
      path = activateNixOnDroid nodConfig;
    };
  };
in
{
  nixOnDroidConfigurations.${name} = nodConfig;
  deploy.nodes.${name} = deployNode;
}
