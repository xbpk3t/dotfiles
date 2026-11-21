# nixos-usb: fleet-visible facts only.
# 便携 U 盘系统，部署/代理都走 tailnet。
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "24.11";

  tailscale = {
    ip = "100.87.217.1";
    role = "ws";
  };
  ssh.user = "luck";

  deploy = {
    # 注意：deploy-rs 的 sshUser 取 ssh.user（= luck）优先，这里不要写 sshUser；
    # 目标机 root 激活由 profile 的 user = "root" 保证。
    # U 盘系统不远程构建：在构建机（VPS/Mac）构建，推 closure 到 U 盘。
    # Why: 插到公司/未知机器上，目标机构建环境不可控。
    remoteBuild = false;
  };
}
