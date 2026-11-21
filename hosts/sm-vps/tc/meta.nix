# sm-vps-tc: fleet-visible facts only.
# 腾讯云 Debian 13 真机（system-manager 平行轨）。
{
  kind = "sm";
  system = "x86_64-linux";
  stateVersion = "24.11";

  # sm-vps 都是 VPS 角色；用于未来切回 tailnet 时选择 VPS auth key。
  tailscale.role = "vps";

  # 公网 IPv4：tc 目前不跑 derper，没有 DERP/DNS 消费者；保留供未来服务记录使用。
  publicIpv4 = "43.156.103.43";

  # tc 不再跑 derper（DERP 只保留 agt，见 terranix.nix 的 derpMap）。

  deploy = {
    remoteBuild = true;
  };

  # bootstrap 后 SSH 目标：luck + 公网 IP（root 密码登录仅用于首次建用户）。
  # opts 直连（无 ProxyJump）；跨境链路（~207ms RTT）+ 真机 remote build 耗时长，
  # 加 ServerAlive 防 nix-daemon 构建期间 SSH 超时断连（Phase 8 实测坑）。
  ssh = {
    host = "43.156.103.43";
    user = "luck";
    opts = [
      "-o"
      "ServerAliveInterval=30"
      "-o"
      "ServerAliveCountMax=20"
    ];
  };
}
