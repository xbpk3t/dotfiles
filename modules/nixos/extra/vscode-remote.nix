{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.modules.extra.vscode-remote;
in {
  options.modules.extra.vscode-remote = with lib; {
    enable = mkEnableOption "Enable VSCode Server (remote SSH target)";
  };

  # 总是导入 upstream vscode-server 模块，避免在 imports 阶段引用 config 触发递归
  imports = [inputs.vscode-server.nixosModules.default];

  config = lib.mkIf cfg.enable {
    services.vscode-server = {
      enable = true;
      # NixOS 无法直接运行上游预编译二进制；FHS 环境让其可运行
      # - VS Code Server 和许多扩展自带的预编译二进制假定 FHS 路径(/bin/sh, /usr/lib, glibc 版本等)。纯 Nix 环境下路径被 sandbox，会缺依赖。
      # - 开启 enableFHS = true 会用 buildFHSUserEnv 启一个兼容的 FHS 环境包装VS Code Server 进程，把常见工具和动态库按 FHS 布局提供，避免“missinglibstdc++/GLIBC”之类错误。
      # - 关闭也能跑，但遇到二进制扩展报缺库时需要手动补 RPATH/依赖，维护成本高。建议默认开启。
      enableFHS = true;

      # 为 server 进程提供的 Node 版本（与 upstream 兼容）
      # - VS Code Server 内置自己的 Node（版本随上游变动）。有些扩展或你自己想要指定 Node 版本，或需要系统上统一版本时，可把 nodejsPackage =pkgs.nodejs_20;，这样会用 Nix 提供的 Node 替换内置 Node。
      #- 不指定则用内置 Node，通常也能工作。只有当你遇到 Node 兼容/安全策略（需固定版本）需求时再指定。
      nodejsPackage = pkgs.nodejs_20;
      # 运行时需要的基础工具（git/posix 核心）
      # - 当 enableFHS 开启时，它把这些包加入 FHS 容器，让 VS Code Server 及扩展能调用（如 git、bash、coreutils、语言运行时）。
      # - 当未开 FHS 时，这列表用于自动补丁 ELF 的 RPATH，把这些包的库路径注入VS Code Server 里的二进制，减少缺库问题。
      # - 实践上建议至少放 git、bashInteractive、coreutils；若某些扩展需要特定运行时（如 python311, nodejs、docker-cli），可加进去。
      extraRuntimeDependencies = with pkgs; [git bashInteractive coreutils];
      # 支持 stable 与 insiders 两个安装前缀
      # - VS Code Server 会按不同客户端通道写入不同目录：~/.vscode-server（Stable）、~/.vscode-server-insiders、~/.vscode-server-oss。
      #- 这个选项让你声明需要监控/修补的安装目录列表。用多个 VS Code 变体时，把对应路径都列上；只用 Stable 保持默认即可。
      installPath = [
        "$HOME/.vscode-server"
        "$HOME/.vscode-server-insiders"
      ];
    };

    # 允许用户会话常驻，保证 auto-fix-vscode-server 等 user services 重启后自动运行
    # services.logind.lingerUsers = ["luck"];
  };
}
