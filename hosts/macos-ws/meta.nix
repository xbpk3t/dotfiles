# macos-ws: fleet-visible facts only.
{
  kind = "darwin";
  system = "aarch64-darwin";
  stateVersion = "24.11";

  # fleet SSH 统一寻址：ssh.nix 只认 tailscale.ip。
  tailscale = {
    ip = "100.87.216.84";
    role = "ws";
  };

  deploy = {
    remoteBuild = true;
    # 本机 localhost 激活成功后 deploy-rs 的 confirmation waiter 偶发超时，
    # 会误判失败并回滚；本机部署关闭 magic rollback。
    magicRollback = false;
  };

  ssh = {
    # 部署入口：VPS 通过 tailnet 直连 Mac。
    # 不写 ssh.host：地址由 fleet.primaryHostForNode 取 tailscale.ip，避免两处 IP 漂移。
    # 首次连接自动记录 host key：Mac/VPS 两边发起都无需手动 ssh-keyscan。
    # tailnet 内 TOFU 可接受；host key 真变了仍会报错。
    opts = [
      "-o"
      "StrictHostKeyChecking=accept-new"
    ];
    user = "luck";
  };
}
