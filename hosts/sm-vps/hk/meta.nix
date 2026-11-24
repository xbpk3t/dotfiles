# sm-vps-hk: fleet-visible facts only.
# 共享 VPS（腾讯云香港）；shared 策略属于 host 模块，不在 meta 里。
{
  kind = "sm";
  system = "x86_64-linux";
  stateVersion = "24.11";

  deploy = {
    remoteBuild = true;
    # 机器已下线；保留配置/Ansible 工具，但不参与 auto。
    auto = false;
  };

  ssh = {
    host = "103.79.184.82";
    user = "luck";
    opts = [
      "-o"
      "ServerAliveInterval=30"
      "-o"
      "ServerAliveCountMax=20"
    ];
  };
}
