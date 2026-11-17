# macos-ws: fleet-visible facts only.
{
  kind = "darwin";
  system = "aarch64-darwin";
  stateVersion = "24.11";

  # fleet SSH 统一寻址：ssh.nix 只认 tailscale.ip。
  tailscale.ip = "100.87.216.84";

  ssh = {
    # 部署入口：VPS 通过 tailnet 直连 Mac；本地部署仍可用 127.0.0.1。
    host = "100.87.216.84";
    # 首次连接自动记录 host key：Mac/VPS 两边发起都无需手动 ssh-keyscan。
    # tailnet 内 TOFU 可接受；host key 真变了仍会报错。
    opts = [
      "-o"
      "StrictHostKeyChecking=accept-new"
    ];
    user = "luck";
  };
}
