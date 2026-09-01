_: {
  modules.networking = {
    # Mihomo (Clash.Meta) proxy service (client)
    # wild 订阅源由 sops 自动发现（SUB_* secrets → sub.<name>），host 无需配置
    mihomo-client.enable = true;
  };

  # https://mynixos.com/nix-darwin/options/launchd
  # 之所以放在这里，因为不同host的launchd本就不同
  #
  # ——— [2026-08-18] 磁盘治理：根权限清理 ———
  # 用户态清理（go-build / docker prune / var/folders / mole cleanup）走 dagu（home/base/AI/dagu/mac.yml，每月）；
  # nix generations 裁剪由 nh.clean（HM LaunchAgent）负责，不再需要 host 级 daemon。
}
