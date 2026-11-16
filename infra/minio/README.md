# MinIO

## 已删除的 k3s Loki stack

`infra/minio/loki/` 已随 k3s/manifests 清理一起删除。它的远程资源（bucket `k3s-test-1-loki-chunks`、lifecycle、IAM user/policy/service account）不会因为删掉 Terraform 代码而自动销毁。

如需彻底清理这些远程资源：

1. 从清理前的 commit `e1d7990e` 取出旧 stack：

   ```bash
   git worktree add /tmp/loki-cleanup e1d7990e
   ```

2. 在临时 worktree 里配置 MinIO 与 S3 backend 凭据（不要提交）：

   ```bash
   export MINIO_USER=ryan
   export MINIO_PASSWORD='...'
   export AWS_ACCESS_KEY_ID='...'
   export AWS_SECRET_ACCESS_KEY='...'
   ```

3. 先 plan，确认销毁列表：

   ```bash
   tofu -chdir=/tmp/loki-cleanup/infra/minio/loki init
   tofu -chdir=/tmp/loki-cleanup/infra/minio/loki plan -destroy
   ```

4. 确认 bucket 里没有还需要的数据后执行销毁：

   ```bash
   tofu -chdir=/tmp/loki-cleanup/infra/minio/loki destroy
   ```

5. 清理临时 worktree：

   ```bash
   git worktree remove /tmp/loki-cleanup
   ```

注意：`k3s-test-1-loki-chunks` 是旧 k3s 测试环境的 Loki chunk bucket；执行 `destroy` 前请确认其中没有需要保留的数据。
