# sm-vps 角色：用户态声明（standalone HM）。
# 与 nixos 轨 hosts/<role>/home.nix 对齐——home/core 由 sm-vps.nix 统一 import，
# 这里点选 home/core 已有的 modules.*.enable 开关（见 home/core/infra/*.nix）。
{
  modules = {
    # Nix 工具（nix-index/nh/comma/cloudflared/deploy-rs）——sm-vps 是 Nix 机器，有用。
    infra.nh.enable = true;
  };
}
