# sm-vps — system-manager + standalone HM 平行轨（非 NixOS）
# 角色目录；配置入口见 outputs/x86_64-linux/src/sm-vps.nix
#
# 节点（inventory 组 sm-vps，同一 role 文件遍历产出三出口）：
#   sm-vps-lab  — Incus 试验床（nixos-vps-dev 上的 Debian 容器）
#   sm-vps-tc   — 腾讯云 Debian 13 真机（43.156.103.43，tailnet 100.111.44.14）
#
# bootstrap：
#   hosts/sm-vps/bootstrap/phase2-hm.sh   — (lab) Determinate Nix + standalone HM switch
#   hosts/sm-vps/bootstrap/phase3-sops.sh — (lab) 用户向 sops
#   hosts/sm-vps/bootstrap/phase8-real.sh — (真机) SSH 直连全流程 bootstrap
#   hosts/sm-vps/bootstrap/phase8-resume.sh — (真机) 中断后增量续跑
#
# 真机 bootstrap 要点（sm-vps-tc）：
#   ROOT_PASS='<初始root密码>' ./hosts/sm-vps/bootstrap/phase8-real.sh
#   - 建 luck 用户 + SSH key + NOPASSWD sudo → 验 key 登录 → 才锁 sshd
#   - Determinate Nix（多用户）→ rsync flake → HM switch → sm switch → sops
#   - tailscale 官方脚本 + tailscale up --authkey=file:...
#   - age key 用 Darwin sops 路径（~/Library/Application Support/sops/age/keys.txt）
#     ——公钥 age10prwj4… 才是 secrets.yaml 接收方；~/.config 那把是 age1atysh…，解不开
#   - Lighthouse 镜像预建 lighthouse(1000)，luck 用 UID 1001
#   - sm switch 的 sudo 需完整 nix 路径（sudo 重置 PATH）
