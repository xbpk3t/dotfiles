# sm-vps — system-manager + standalone HM 平行轨（非 NixOS）
# 角色目录；配置入口见 outputs/x86_64-linux/src/sm-vps.nix
# bootstrap：hosts/sm-vps/bootstrap/（容器 linux-sm-lab）
#   phase2-hm.sh     — Determinate Nix + standalone HM switch
#   phase3-sops.sh   — 用户向 sops（age key + linger + 验证 secret 可读）
