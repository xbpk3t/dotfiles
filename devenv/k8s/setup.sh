#!/usr/bin/env bash
# K8s PAG Development Environment Setup
# 使用 Helm + Kustomize 管理本地 Prometheus Operator 环境

set -euo pipefail

# 默认配置
K8S_CLUSTER="${K8S_CLUSTER:-kind}"
K8S_CLUSTER_NAME="${K8S_CLUSTER_NAME:-pag-dev}"
NAMESPACE="${NAMESPACE:-monitoring}"
HELM_RELEASE_NAME="${HELM_RELEASE_NAME:-pag}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖工具
check_dependencies() {
    log_info "检查依赖工具..."

    local tools=("helm" "kubectl" "kustomize")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool 未安装"
            return 1
        fi
    done

    # 检查集群工具
    case "$K8S_CLUSTER" in
        kind)
            if ! command -v kind &> /dev/null; then
                log_error "kind 未安装"
                return 1
            fi
            ;;
        minikube)
            if ! command -v minikube &> /dev/null; then
                log_error "minikube 未安装"
                return 1
            fi
            ;;
        k3d)
            if ! command -v k3d &> /dev/null; then
                log_error "k3d 未安装"
                return 1
            fi
            ;;
        *)
            log_error "不支持的 K8S 集群类型: $K8S_CLUSTER"
            return 1
            ;;
    esac

    log_success "所有依赖工具已就绪"
}

# 创建本地集群
create_cluster() {
    log_info "创建 $K8S_CLUSTER 集群: $K8S_CLUSTER_NAME"

    case "$K8S_CLUSTER" in
        kind)
            create_kind_cluster
            ;;
        minikube)
            create_minikube_cluster
            ;;
        k3d)
            create_k3d_cluster
            ;;
    esac
}

# 创建 Kind 集群
create_kind_cluster() {
    local config_file="./k8s/kind-config.yaml"

    if [[ ! -f "$config_file" ]]; then
        log_info "创建 Kind 配置文件..."
        cat > "$config_file" << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${K8S_CLUSTER_NAME}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30000-30100
    hostPort: 30000-30100
    protocol: TCP
EOF
    fi

    if ! kind get clusters | grep -q "^${K8S_CLUSTER_NAME}$"; then
        kind create cluster --config "$config_file"
        log_success "Kind 集群创建成功"
    else
        log_warn "集群已存在，跳过创建"
    fi
}

# 创建 Minikube 集群
create_minikube_cluster() {
    if ! minikube status | grep -q "Running"; then
        minikube start \
            --driver=docker \
            --profile="$K8S_CLUSTER_NAME" \
            --memory=4096 \
            --cpus=2 \
            --disk-size=20g \
            --ports=80:80,443:443
        log_success "Minikube 集群创建成功"
    else
        log_warn "Minikube 集群已在运行"
    fi
}

# 创建 k3d 集群
create_k3d_cluster() {
    if ! k3d cluster list | grep -q "^${K8S_CLUSTER_NAME}"; then
        k3d cluster create "$K8S_CLUSTER_NAME" \
            --agents 1 \
            --port "80:80@agent[0]" \
            --port "443:443@agent[0]" \
            --port "30000-30100:30000-30100@agent[0]"
        log_success "k3d 集群创建成功"
    else
        log_warn "k3d 集群已存在，跳过创建"
    fi
}

# 安装 Helm 仓库
setup_helm_repos() {
    log_info "设置 Helm 仓库..."

    # Prometheus Community 仓库
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add bitnami https://charts.bitnami.com/bitnami

    helm repo update
    log_success "Helm 仓库设置完成"
}

# 安装 CRDs
install_crds() {
    log_info "安装 Prometheus Operator CRDs..."

    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml

    log_success "CRDs 安装完成"
}

# 安装 Prometheus Operator
install_prometheus_operator() {
    log_info "安装 Prometheus Operator..."

    helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --wait \
        --values ./k8s/helm-values/prometheus-operator-values.yaml \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set grafana.adminPassword=admin123 \
        --set grafana.service.type=LoadBalancer

    log_success "Prometheus Operator 安装完成"
}

# 安装 MySQL
install_mysql() {
    log_info "安装 MySQL..."

    helm upgrade --install mysql bitnami/mysql \
        --namespace "$NAMESPACE" \
        --values ./k8s/helm-values/mysql-values.yaml \
        --set auth.rootPassword=rootpassword \
        --set auth.database=pag_dev \
        --set auth.username=pag_user \
        --set auth.password=pag_password

    log_success "MySQL 安装完成"
}

# 应用 Kustomize 配置
apply_kustomize() {
    log_info "应用 Kustomize 配置..."

    kubectl apply -k ./k8s/overlays/dev
    log_success "Kustomize 配置应用完成"
}

# 等待所有 Pod 就绪
wait_for_pods() {
    log_info "等待所有 Pod 就绪..."

    kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=pag \
        --namespace "$NAMESPACE" \
        --timeout=300s

    log_success "所有 Pod 已就绪"
}

# 显示访问信息
show_access_info() {
    log_info "获取服务访问信息..."

    echo
    echo "=== PAG 开发环境访问信息 ==="
    echo

    # Grafana
    local grafana_port=$(kubectl get svc prometheus-operator-grafana -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
    echo "🔗 Grafana: http://localhost:$grafana_port"
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo

    # Prometheus
    local prometheus_port=$(kubectl get svc prometheus-operator-kube-p-prometheus -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
    echo "🔗 Prometheus: http://localhost:$prometheus_port"
    echo

    # Alertmanager
    local alertmanager_port=$(kubectl get svc prometheus-operator-kube-p-alertmanager -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
    echo "🔗 Alertmanager: http://localhost:$alertmanager_port"
    echo

    # Nightingale (如果安装)
    if kubectl get svc nightingale -n "$NAMESPACE" &>/dev/null; then
        local nightingale_port=$(kubectl get svc nightingale -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
        echo "🔗 Nightingale: http://localhost:$nightingale_port"
        echo
    fi

    echo "=== 管理命令 ==="
    echo "查看所有 Pod: kubectl get pods -n $NAMESPACE"
    echo "查看日志: kubectl logs -f <pod-name> -n $NAMESPACE"
    echo "进入容器: kubectl exec -it <pod-name> -n $NAMESPACE -- bash"
    echo
}

# 主函数
main() {
    log_info "开始设置 K8s PAG 开发环境..."

    check_dependencies
    create_cluster
    setup_helm_repos
    install_crds
    install_prometheus_operator
    install_mysql
    apply_kustomize
    wait_for_pods
    show_access_info

    log_success "K8s PAG 开发环境设置完成！"
}

# 脚本选项
case "${1:-}" in
    "destroy")
        log_info "销毁集群..."
        case "$K8S_CLUSTER" in
            kind)
                kind delete cluster --name "$K8S_CLUSTER_NAME"
                ;;
            minikube)
                minikube stop --profile="$K8S_CLUSTER_NAME"
                minikube delete --profile="$K8S_CLUSTER_NAME"
                ;;
            k3d)
                k3d cluster delete "$K8S_CLUSTER_NAME"
                ;;
        esac
        log_success "集群销毁完成"
        ;;
    "status")
        log_info "集群状态:"
        kubectl cluster-info
        echo
        echo "命名空间 $NAMESPACE 中的 Pod:"
        kubectl get pods -n "$NAMESPACE"
        ;;
    "logs")
        shift
        if [[ -z "${1:-}" ]]; then
            log_error "请指定 Pod 名称"
            exit 1
        fi
        kubectl logs -f "$1" -n "$NAMESPACE"
        ;;
    "shell")
        shift
        if [[ -z "${1:-}" ]]; then
            log_error "请指定 Pod 名称"
            exit 1
        fi
        kubectl exec -it "$1" -n "$NAMESPACE" -- bash
        ;;
    *)
        main "$@"
        ;;
esac
