---
title: Cluster Config and Secret Operations
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, flux, secrets, sops]
summary: 记录本仓库集群配置目录里常见的 secret 生成、加密与更新操作。
---

# Cluster Config and Secret Operations

本文整理 [`manifests/config/`](dotfiles/manifests/config) 下目前仍需要人工处理的配置与 secret 操作。

## Cluster Secrets

Kubernetes Secret 是 immutable 的。修改内容后，可能需要先手动删除旧 Secret，再重新应用。

### Encrypt

```bash
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place ./cluster-secrets.example.yaml
```

### Decrypt

```bash
sops --decrypt --in-place ./cluster-secrets.example.yaml
```

### Edit Secrets on a New PC

把 `AGE-SECRET-KEY` 写入 `~/.config/sops/age/keys.txt`。如果文件不存在就先创建。完成后即可在本机直接执行 `sops` 的加解密命令。

### `.sops.yaml`

仓库根目录的 `.sops.yaml` 已经定义了加密规则，因此只要本机装好了 key，就可以直接使用：

```bash
sops --encrypt --in-place [FILE]
sops --decrypt --in-place [FILE]
```

## Examples

### VPN Config

```bash
kubectl -n vpn-gateway create secret generic openvpn-config --dry-run=client --from-file=vpnConfigfile=./INPUT_FILENAME.ovpn -o yaml > vpn-config.sops.yaml
sops --encrypt --in-place vpn-config.sops.yaml
```

### Self-Signed CA

```bash
kubectl -n networking create secret tls internal-ca --dry-run=client --cert=ca.crt --key=ca.key -o yaml > ca-certs.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place ca-certs.sops.yaml
```

注意：`ca.key` 必须是无 passphrase 的私钥。可以这样去掉 passphrase：

```bash
openssl rsa -in ca.key -out ca2.key
```

### Vault Auto-Unseal

如果要重新初始化 Vault key，需要先删除：

- `./secrets/vault-root-token.sops.yaml`
- `./secrets/vault-keys.sops.yaml`

同时把它们从 `./kustomization.yaml` 中移除。等 cluster 用 Flux 初始化完成后，再重新导出并加密：

```bash
kubectl get secrets vault-root-token -o yaml -n apps > vault-root-token.sops.yaml
kubectl get secrets vault-keys -o yaml -n apps > vault-keys.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-root-token.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-keys.sops.yaml
```

### Authelia Keys

```bash
openssl genrsa -out private.pem 4096
kubectl -n security create secret generic authelia-keys --dry-run=client --from-file=oidcIssuerPrivateKey=./private.pem -o yaml > authelia-keys.sops.yaml
rm private.pem
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place authelia-keys.sops.yaml
```

### Jellyplist Spotify Cookie

```bash
kubectl -n media create secret generic jellyplist-spotify-cookie --dry-run=client --from-file=vpnConfigfile=./cookies.txt -o yaml > jellyplist-spotify-cookie.sops.yaml
sops --encrypt --in-place jellyplist-spotify-cookie.sops.yaml
```
