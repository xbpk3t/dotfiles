if ! ${pkgs.iproute2}/bin/ip link show cni0 >/dev/null 2>&1; then
  exit 0
fi
cidr="$(${pkgs.iproute2}/bin/ip -4 addr show cni0 | ${pkgs.gawk}/bin/awk '/inet / {print $2; exit}')"
if [ -n "$cidr" ]; then
  net="$(CIDR="$cidr" ${pkgs.python3}/bin/python - <<'PY'
import ipaddress, os
cidr = os.environ.get("CIDR", "")
if cidr:
    print(ipaddress.ip_network(cidr, strict=False))
PY
  )"
  if [ -n "$net" ]; then
    ${pkgs.iproute2}/bin/ip route replace "$net" dev cni0
  fi
fi
