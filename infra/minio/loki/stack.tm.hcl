stack {
  name        = "minio-loki"
  description = "Legacy root module for Loki buckets and credentials on MinIO."
  tags = [
    "layer-infra",
    "legacy",
    "minio",
    "loki",
    "env-homelab",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/minio/loki"
}
