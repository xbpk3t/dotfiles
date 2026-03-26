

## NixOS 模块约定

- 对于 `modules/nixos/base` 里的“能力型模块”，优先只定义 options 和实现本身，不要再为了 `vps`、`homelab` 之类角色额外创建只包含 `enable = true` 的薄包装模块。
- 角色是否启用某个能力，优先直接在对应 `hosts/<name>/default.nix` 里声明；如果后续需要自定义参数，也直接在 host 层处理。
- 遇到容易和上游 NixOS 选项混淆的模块名时，命名要尽量体现语义边界；例如区分 `systemd Manager watchdog` 与 `services.watchdogd`。


## pkgs

用来存放自己打包的一些pkg


## Notice

注意修改代码，不要轻易修改 `docs/<topic>/review` 里的相关内容