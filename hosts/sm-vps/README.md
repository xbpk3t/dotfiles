# sm-vps — system-manager + standalone HM 平行轨（非 NixOS）
# 角色目录；配置入口见 outputs/x86_64-linux/src/sm-vps.nix
#
# 节点（inventory 组 sm-vps，同一 role 文件遍历产出三出口）：
#   sm-vps-tc   — 腾讯云 Debian 13 真机（43.156.103.43，tailnet 100.111.44.14）
#   （原 sm-vps-lab Incus 试验床已废弃删除，2026-08-13）
#
# bootstrap（Ansible 版，替代原 shell 脚本）：
#   hosts/sm-vps/ansible/  — playbook + inventory + group_vars + README
#   用法见 hosts/sm-vps/ansible/README.md
#
# 真机 bootstrap 要点（Ansible）：
#   - 建 luck 用户 + SSH key + NOPASSWD sudo → P1 验 key 登录 → P4 才锁 sshd
#   - Determinate Nix（get_url + creates 幂等）→ rsync flake → HM switch → sm switch
#   - tailscale 官方 repo + package
#   - age key 用 Darwin sops 路径（~/Library/Application Support/sops/age/keys.txt）
#     ——公钥 age10prwj4… 才是 secrets.yaml 接收方；~/.config 那把是 age1atysh…，解不开
#   - Lighthouse 镜像预建 lighthouse(1000)，luck 用 UID 1001
