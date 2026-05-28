#!/usr/bin/env bash
set -euo pipefail

# 说明：该脚本建议在 homelab 上执行（已具备 kubectl/flux 访问权限）
# 作用：拉取代码、同步 Flux、打节点标签、校验 memos/rsshub 是否就绪

REPO_DIR="${REPO_DIR:-$HOME/dotfiles}"
FLUX_NS="${FLUX_NS:-flux-system}"
FLUX_GIT_NAME="${FLUX_GIT_NAME:-flux-system}"
FLUX_OWNER="${FLUX_OWNER:-xbpk3t}"
FLUX_REPO="${FLUX_REPO:-dotfiles}"
# What：默认对齐部署分支为 PaaS。
# Why：该分支承载当前集群所需的 k3s/Flux 配置。
FLUX_BRANCH="${FLUX_BRANCH:-PaaS}"
FLUX_PATH="${FLUX_PATH:-manifests/flux}"

info() {
  printf "[INFO] %s\n" "$*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf "[ERROR] 缺少命令：%s\n" "$1" >&2
    exit 1
  }
}

need_cmd kubectl
need_cmd flux

if command -v git >/dev/null 2>&1 && [[ -d "$REPO_DIR/.git" ]]; then
  info "更新本地仓库：$REPO_DIR"
  git -C "$REPO_DIR" pull --ff-only
else
  info "未发现本地仓库，跳过 git pull（仅执行 Flux 同步）"
fi

if [[ "${1:-}" == "--bootstrap" ]]; then
  # 首次初始化时使用（已有 Flux 则无需重复执行）
  info "执行 Flux Bootstrap（首次安装用）"
  flux bootstrap github \
    --owner="$FLUX_OWNER" \
    --repository="$FLUX_REPO" \
    --branch="$FLUX_BRANCH" \
    --path="$FLUX_PATH" \
    --personal
fi

info "同步 Flux GitRepository"
flux reconcile source git -n "$FLUX_NS" "$FLUX_GIT_NAME"

info "按依赖顺序触发 Kustomization"
flux reconcile kustomization -n "$FLUX_NS" namespaces --with-source
flux reconcile kustomization -n "$FLUX_NS" sources --with-source
flux reconcile kustomization -n "$FLUX_NS" core --with-source
flux reconcile kustomization -n "$FLUX_NS" config --with-source
flux reconcile kustomization -n "$FLUX_NS" apps --with-source

# 重要：节点标签用于调度 memos/rsshub 到 HK
info "为节点打标准标签（拓扑 + 业务角色）"
kubectl label node nixos-vps-svc \
  topology.kubernetes.io/region=APAC \
  topology.kubernetes.io/zone=HK \
  node-role.kubernetes.io/svc=true \
  --overwrite

kubectl label node nixos-vps-dev \
  topology.kubernetes.io/region=NA \
  topology.kubernetes.io/zone=LA \
  node-role.kubernetes.io/dev=true \
  --overwrite

info "检查 memos/rsshub 就绪状态"
kubectl rollout status deployment/memos --timeout=120s
kubectl rollout status deployment/rsshub --timeout=120s
# What：browserless 可能是可选组件。
# Why：不阻断主链路（memos/rsshub）上线。
kubectl rollout status deployment/browserless --timeout=120s || true

info "检查 Ingress"
kubectl get ingress memos rsshub

info "完成"
