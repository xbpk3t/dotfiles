# infra 工具链 —— 单一手写清单。
#
# 为什么存在：
#   home-manager 的 modules.devops.tf 与 CI/本地 devShells.infra 消费同一套
#   OpenTofu 工具。两处各自手写包列表会在换包/升级时漂移；这里按能力分组，
#   消费端按需拼接（与 lib/precommit-tools.nix 同一模式）。
#
# 不包含 ansible：它只是 home profile 的可选能力，devShell 不需要。
{ pkgs }:
with pkgs;
{
  # OpenTofu 本体 + terranix；provider 由各 stack 的 .terraform.lock.hcl 锁定，
  # 不使用 opentofu.withPlugins 预打包。
  opentofu = [
    opentofu
    terranix
  ];

  # tenv 与 terramate 提供同名二进制，不启用。
  terramate = [ terramate ];

  # === Terraform 代码质量 ===
  lint = [
    tflint
    terraform-docs
  ];

  # 只进 devShell / CI、不装进 home profile 的工具。
  ci = [
    jq
    actionlint
    go-task
  ];
}
