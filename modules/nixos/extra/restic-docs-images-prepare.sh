set -euo pipefail
install -d -m 0700 -o root -g root /run/restic
cat > /run/restic/docs-images.env <<EOF
AWS_ACCESS_KEY_ID=$(cat ${config.sops.secrets.rcloneR2AccessKeyId.path})
AWS_SECRET_ACCESS_KEY=$(cat ${config.sops.secrets.rcloneR2SecretAccessKey.path})
AWS_DEFAULT_REGION=auto
EOF
chmod 0400 /run/restic/docs-images.env
