{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.cc-connect;
in
{
  options.modules.AI.cc-connect = with lib; {
    enable = mkEnableOption "Enable cc-connect daemon";
  };

  config = lib.mkIf cfg.enable {

    home = {
      packages = with pkgs; [
        cc-connect
      ];

      file.".cc-connect/config.toml" = {
        source = ./cc-connect.toml;
        force = true;
      };

      # FEISHU_APP_SECRET 是 cc-connect 的 TOML 变量展开所需的 env var，
      # 由 sops-nix 统一注入，所有 host 都能拿到。
      sessionVariables = {
        FEISHU_APP_SECRET = "$(cat ${config.sops.secrets.FEISHU_APP_SECRET.path})";
      };
    };

    # ─────────────────────────────────────────────────────────────
    # 手动部署说明（非声明式）
    #
    # cc-connect 的 systemd service 由 cc-connect daemon install 手动管理。
    # 不做声明式的原因：
    #
    # 1. 环境变量捕获问题
    #    cc-connect daemon install 在运行时从 shell 环境捕获
    #    ANTHROPIC_AUTH_TOKEN、ANTHROPIC_BASE_URL 等变量并写入
    #    systemd unit。Nix 声明式方式无法正确处理 $(cat ...) 展开。
    #
    # 2. NixOS containers 模块兼容问题
    #    当前 nixpkgs-unstable (2026-06) 下，容器 config 中显式设置
    #    nixpkgs.pkgs 会触发 nixos-containers.nix 的断言失败
    #    （config vs externally created pkgs 冲突），导致无法独立
    #    eval 容器 deploy node。
    #
    # 3. 过渡工具定位
    #    cc-connect 属于社区临时方案（BYOM 用户被 Claude Code 官方
    #    远程方案排除），投入大量 Nix 定制成本 > 收益。
    #    等官方 Remote Control 支持 BYOM 后自然淘汰。
    #
    # 容器重建后重新部署步骤：
    #   1. task nix:deploy -- nixos-vps-dev    # 部署宿主机（容器一起更新）
    #   2. ssh -J root@192.129.183.26 luck@10.233.0.2
    #   3. cc-connect feishu setup --project docs   # 重新配飞书
    #   4. cc-connect daemon install --force --config ~/.cc-connect/config.toml
    #   5. cc-connect daemon start
    #
    # cc-connect 通过 provider 的 env 字段显式传递
    # ANTHROPIC_AUTH_TOKEN + ANTHROPIC_BASE_URL 给 Claude Code 子进程，
    # 不依赖 systemd 环境继承。参见 cc-connect.reference.toml。
    # ─────────────────────────────────────────────────────────────
  };
}
