stack {
  name        = "minio-tf-s3-backend"
  description = "Legacy root module for the MinIO-backed Terraform state bucket and credentials."
  tags = [
    "layer-infra",
    "legacy",
    "bootstrap",
    "minio",
    "state-backend",
    "env-homelab",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/minio/tf-s3-backend"
}
