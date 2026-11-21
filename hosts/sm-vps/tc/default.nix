# sm-vps-tc：dedicated VPS（腾讯云 Debian 13）。
# 基线能力在 group base；这里只声明专属的服务角色和 sops。
{
  ...
}:
{
  imports = [ ../default.nix ];

  modules = {
    sm.sops.enable = true;

    infra = {
      singbox-server.enable = true;
      # DERP 只保留 agt；tc 回来时不再跑 derper。
      status-page.enable = true;
    };
  };
}
