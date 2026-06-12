#!/usr/bin/env bash
# MAYBE: [2026-05-21](shell-to-nushell) eval 是否有必要把dotfiles所有shell -> nushll. 暂时来说没必要，因为看了一下大部分都是 shell 都与 k3s 相关，暂时搁置。到时候处理k3s时，作为优化，捎带手处理掉。
# [2026-05-28] 处理了一轮，把所有shell，该删的删，该转的转。之后处理k3s时，把k3s相关shell处理掉即可。
set -euo pipefail

if ! ip link show cni0 >/dev/null 2>&1; then
  exit 0
fi
cidr="$(ip -4 addr show cni0 | awk '/inet / {print $2; exit}')"
if [ -n "$cidr" ]; then
  net="$(CIDR="$cidr" python3 - <<'PY'
import ipaddress, os
cidr = os.environ.get("CIDR", "")
if cidr:
    print(ipaddress.ip_network(cidr, strict=False))
PY
  )"
  if [ -n "$net" ]; then
    ip route replace "$net" dev cni0
  fi
fi
