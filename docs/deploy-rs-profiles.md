# deploy-rs 跨 profile 输出模板

> 目的：提供 darwin / nix-on-droid 的 deploy 输出模板，避免每次手写。

## 1) nix-darwin 模板（deploy.nodes）

```nix
{
  # 仅示意：把已有 darwinConfiguration 转成 deploy-rs profile
  deploy.nodes.macos-ws = let
    deployLib = inputs."deploy-rs".lib."aarch64-darwin";
    darwinConfig = self.darwinConfigurations.macos-ws;
  in {
    hostname = "macos-ws"; # 可改为 SSH Host/Alias
    sshUser = "luck";      # SSH 用户
    profiles.system = {
      user = "root";
      # nix-darwin 的 system closure 内含 activate 脚本
      path = deployLib.activate.custom darwinConfig.system "./activate";
    };
  };
}
```

要点：

- deploy-rs 提供 `activate.custom`，允许给任意 derivation 附加激活脚本。citeturn7search0
- nix-darwin 需要自定义 activation，常用做法是调用系统 closure 里的 `./activate`。

## 2) nix-on-droid 模板（deploy.nodes）

```nix
{
  # 仅示意：nix-on-droid 的配置输出包含 activationPackage
  deploy.nodes.nix-on-droid-phone = let
    deployLib = inputs."deploy-rs".lib."aarch64-linux";
    nod = self.nixOnDroidConfigurations.phone;
  in {
    hostname = "phone-ssh"; # 例如 termux 的 SSH
    sshUser = "u0_a123";    # termux 用户
    profiles.system = {
      user = "u0_a123";
      # activationPackage 是 nix-on-droid 输出的一部分
      path = deployLib.activate.custom nod.activationPackage "./activate";
    };
  };
}
```

要点：

- nix-on-droid 配置输出暴露 `activationPackage`。citeturn8search0
- nix-on-droid CLI 也会从 flake 输出读取 `.activationPackage`。citeturn8search1

---

## 3) 使用 deploy-rs 的通用提示

- NixOS 直接用 `activate.nixos`：citeturn7search1

  ```nix
  profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.my-host;
  ```

- 任意自定义 profile 使用 `activate.custom`：citeturn7search0
  ```nix
  profiles.myprofile.path = deploy-rs.lib.x86_64-linux.activate.custom drv "./bin/activate";
  ```
