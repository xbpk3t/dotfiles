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
      enableFHS = true;
      # 为 server 进程提供的 Node 版本（与 upstream 兼容）
      nodejsPackage = pkgs.nodejs_20;
      # 运行时需要的基础工具（git/posix 核心）
      extraRuntimeDependencies = with pkgs; [git bashInteractive coreutils];
      # 支持 stable 与 insiders 两个安装前缀
      installPath = [
        "$HOME/.vscode-server"
        "$HOME/.vscode-server-insiders"
      ];
    };

    # 允许用户会话常驻，保证 auto-fix-vscode-server 等 user services 重启后自动运行
    # services.logind.lingerUsers = ["luck"];
  };
}
