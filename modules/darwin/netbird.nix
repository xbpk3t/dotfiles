{pkgs, ...}: {

  # 本配置非必需，services.netbird 本身会把install netbird，但是我可能需要手动执行 netbird相关命令，所以添加该配置
  environment.systemPackages = with pkgs; [
    # 注意这里应是 netbird，而非 netbird-client
    netbird
  ];

  # 注意nixos本身支持 services.netbird.clients
  # 所以虽然netbird是多端共有的服务，但是配置本身无法复用（不能放到base里）
  services.netbird = {
    enable = true;
    package = pkgs.netbird;
  };
}
