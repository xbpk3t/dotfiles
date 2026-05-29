stack {
  name        = "tailscale-tailnet"
  description = "Tailscale tailnet ACL, DERP map, DNS preferences, and auth keys."
  tags = [
    "layer-infra",
    "env-homelab",
    "tailscale",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/tailscale/tailnet"
}
