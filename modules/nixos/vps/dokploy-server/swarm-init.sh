#!/usr/bin/env sh

# 幂等初始化 Docker Swarm 与 overlay 网络
set -e

  # 查询当前节点 Swarm 状态（active/pending 视为已初始化）
state=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)

# If not part of a swarm, initialize with the primary reachable IP as advertise-addr.
if [ "$state" != "active" ] && [ "$state" != "pending" ]; then
    # 优先用内网路由获取本机可达的源 IP
  ip=$(ip route get 1.1.1.1 2>/dev/null | cut -d" " -f7)
    # 回退：hostname -I 取第一个地址
  [ -z "$ip" ] && ip=$(hostname -I 2>/dev/null | cut -d' ' -f1)
  docker swarm init --advertise-addr "$ip"
fi

  # 创建 overlay 网络（已存在则跳过）
docker network inspect dokploy-network >/dev/null 2>&1 || \
  docker network create --driver overlay --attachable dokploy-network
