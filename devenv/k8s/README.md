# PAG Development Environment with Kubernetes

本目录包含使用 Kubernetes + Helm + Kustomize 搭建的 PAG (Prometheus + Alertmanager + Grafana) 开发环境配置。

## 🏗️ 架构概述

### 核心组件
- **Prometheus Operator**: 管理 Prometheus 实例和相关组件
- **Grafana**: 数据可视化和仪表板
- **Alertmanager**: 告警管理和通知
- **MySQL**: 数据存储
- **Nightingale**: 告警平台 (可选)
- **Categraf**: 指标收集器 (可选)

### 部署方式
- **Helm**: 管理复杂应用的生命周期
- **Kustomize**: 管理配置差异和环境定制
- **本地 Kubernetes**: Kind/Minikube/k3d

## 🚀 快速开始

### 前置要求

```bash
# 安装必需工具
brew install helm kubectl kustomize

# 选择一个本地 K8s 集群工具
brew install kind        # 推荐: 最轻量级
# 或者
brew install minikube    # 功能完整
# 或者
brew install k3d         # 最快的 K3s

# 确保工具已安装
kind version
helm version
kubectl version
kustomize version
```

### 1. 初始化环境

```bash
# 进入项目目录
cd devenv/k8s

# 运行自动化设置脚本
./setup.sh

# 或者手动执行步骤
./setup.sh create-cluster    # 创建集群
./setup.sh install-charts   # 安装 Helm charts
./setup.sh apply-configs     # 应用 Kustomize 配置
```

### 2. 访问服务

设置完成后，脚本会显示所有服务的访问地址：

```
=== PAG 开发环境访问信息 ===

🔗 Grafana: http://localhost:30000
   用户名: admin
   密码: admin123

🔗 Prometheus: http://localhost:30001
🔗 Alertmanager: http://localhost:30002
🔗 Nightingale: http://localhost:30003
```

### 3. 验证部署

```bash
# 检查 Pod 状态
kubectl get pods -n monitoring

# 检查服务状态
kubectl get svc -n monitoring

# 查看日志
kubectl logs -f deployment/prometheus-operator -n monitoring
```

## 📁 目录结构

```
devenv/k8s/
├── setup.sh                    # 自动化设置脚本
├── helm-values/               # Helm values 文件
│   ├── prometheus-operator-values.yaml
│   └── mysql-values.yaml
├── base/                      # 基础配置
│   ├── kustomization.yaml
│   ├── monitoring/           # 监控配置
│   ├── database/             # 数据库配置
│   └── ingress/              # 入口配置
├── overlays/                  # 环境覆盖
│   └── dev/                  # 开发环境
└── components/               # 可复用组件
    ├── dev-logging/          # 开发日志
    └── dev-monitoring/       # 开发监控
```

## ⚙️ 配置管理

### 环境管理

```bash
# 开发环境
kubectl apply -k overlays/dev

# 生产环境 (需要创建)
kubectl apply -k overlays/prod
```

### Helm 值覆盖

```bash
# 自定义 Prometheus 配置
helm upgrade prometheus-operator prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values helm-values/prometheus-operator-values.yaml \
  --set prometheus.prometheusSpec.retention=30d
```

### Kustomize 定制

```bash
# 查看生成的配置
kubectl kustomize overlays/dev

# 预览变更
kubectl diff -k overlays/dev
```

## 🔧 常用操作

### 集群管理

```bash
# 销毁集群
./setup.sh destroy

# 查看集群状态
./setup.sh status

# 重启集群
kind delete cluster --name pag-dev
./setup.sh create-cluster
```

### 调试操作

```bash
# 进入 Pod shell
./setup.sh shell <pod-name>

# 查看日志
./setup.sh logs <pod-name>

# 端口转发
kubectl port-forward svc/prometheus-operator-grafana 3000:80 -n monitoring
```

### 配置更新

```bash
# 更新 Helm Release
helm upgrade prometheus-operator prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values helm-values/prometheus-operator-values.yaml

# 应用 Kustomize 更改
kubectl apply -k overlays/dev
```

## 🌐 本地访问

### 域名配置

在本地 `/etc/hosts` 文件中添加：

```bash
127.0.0.1 grafana.local
127.0.0.1 prometheus.local
127.0.0.1 alertmanager.local
127.0.0.1 nightingale.local
127.0.0.1 mysql.local
```

### Ingress 访问

配置完成后，可以通过以下地址访问：

- **Grafana**: http://grafana.local
- **Prometheus**: http://prometheus.local
- **Alertmanager**: http://alertmanager.local
- **Nightingale**: http://nightingale.local
- **MySQL**: mysql.local:3306

## 🔍 监控和告警

### Grafana 仪表板

预配置的仪表板包括：
- Kubernetes 集群监控
- MySQL 性能监控
- 系统资源监控
- 应用性能监控

### 告警规则

内置告警规则覆盖：
- 服务可用性
- 资源使用率
- 数据库性能
- 应用错误率

### 自定义指标

```bash
# 添加自定义 ServiceMonitor
kubectl apply -f custom-servicemonitor.yaml

# 修改告警规则
kubectl edit prometheusrule pag-alert-rules -n monitoring
```

## 📊 性能优化

### 开发环境优化

- 减少资源限制
- 缩短数据保留期
- 禁用非必要功能
- 启用调试日志

### 生产环境考虑

- 增加 HA 配置
- 配置持久化存储
- 设置资源限制
- 启用安全认证

## 🐛 故障排除

### 常见问题

1. **Pod 无法启动**
   ```bash
   kubectl describe pod <pod-name> -n monitoring
   kubectl logs <pod-name> -n monitoring
   ```

2. **服务无法访问**
   ```bash
   kubectl get svc -n monitoring
   kubectl get endpoints -n monitoring
   ```

3. **Helm 安装失败**
   ```bash
   helm status prometheus-operator -n monitoring
   helm history prometheus-operator -n monitoring
   ```

### 重置环境

```bash
# 完全重置
./setup.sh destroy
rm -rf ~/.kube/config
./setup.sh
```

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。

## 📞 支持

如有问题，请：
1. 查看 [Issues](../../issues)
2. 搜索现有解决方案
3. 创建新的 Issue
