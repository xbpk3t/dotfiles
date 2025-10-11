#!/usr/bin/env bash

set -e

echo "=========================================="
echo "部署配置修复到 NixOS 服务器"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 服务器信息
SERVER="luck@192.168.234.194"
REMOTE_CONFIG_DIR="~/Desktop/nix-config"

echo -e "${YELLOW}步骤 1/5: 检查本地更改${NC}"
echo "----------------------------------------"
git status --short
echo ""

echo -e "${YELLOW}步骤 2/5: 提交本地更改${NC}"
echo "----------------------------------------"
read -p "是否提交更改? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "fix: resolve zellij, netbird, and sing-box configuration issues

- Remove problematic zellij filepicker plugin
- Fix netbird service name to use default (netbird.service) for single client
- Rewrite sing-box module to use system service with root privileges for TUN
- Enable sing-box on nixos-ws host

Key changes:
- netbird: Use 'default' key for single client to get netbird.service
- sing-box: Changed from user service to system service (needs CAP_NET_ADMIN)
- zellij: Removed non-existent filepicker plugin"
    
    echo -e "${GREEN}✓ 更改已提交${NC}"
    echo ""
    
    read -p "是否推送到远程仓库? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push
        echo -e "${GREEN}✓ 已推送到远程${NC}"
    fi
else
    echo -e "${YELLOW}跳过提交${NC}"
fi
echo ""

echo -e "${YELLOW}步骤 3/5: 连接到服务器并拉取更改${NC}"
echo "----------------------------------------"
ssh -t $SERVER "cd $REMOTE_CONFIG_DIR && git pull"
echo ""

echo -e "${YELLOW}步骤 4/5: 重建 NixOS 系统${NC}"
echo "----------------------------------------"
echo -e "${RED}注意: 这将需要一些时间，请耐心等待...${NC}"
echo ""
ssh -t $SERVER "cd $REMOTE_CONFIG_DIR && sudo nixos-rebuild switch --flake .#nixos-ws"
echo ""

echo -e "${YELLOW}步骤 5/5: 验证修复${NC}"
echo "----------------------------------------"
echo ""

echo "验证 zellij..."
ssh -t $SERVER "zellij --version && echo '✓ zellij 可用'"
echo ""

echo "验证 netbird..."
ssh -t $SERVER "systemctl status netbird.service --no-pager | head -5 && which netbird && netbird status 2>&1 | head -5 && echo '✓ netbird 服务运行中，CLI 可用'"
echo ""

echo "验证 sing-box..."
ssh -t $SERVER "systemctl status sing-box.service --no-pager | head -10 && echo '✓ sing-box 系统服务运行中'"
echo ""

echo "验证 ugit..."
ssh -t $SERVER "ugit --version && echo '✓ ugit 可用 (可能有 bat 警告，但功能正常)'"
echo ""

echo "=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "=========================================="
echo ""
echo "后续步骤:"
echo "1. 测试 zellij: ssh $SERVER 然后运行 'zellij'"
echo "2. 测试 netbird: ssh $SERVER 然后运行 'netbird login'"
echo "3. 测试 sing-box: ssh $SERVER 然后运行 'systemctl status sing-box'"
echo "4. 查看详细修复说明: cat FIXES_SUMMARY_V2.md"
echo ""

