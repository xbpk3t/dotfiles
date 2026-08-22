# Darwin-specific modules —— 纯聚合入口，不承载具体配置。
# 所有 darwin 配置拆分在各子目录（infra/networking/desktop），经 scanPaths 自动加载。
# Determinate Nix 的 module import 已在 infra/determinate.nix 自持。
{
  mylib,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  # documentation 关闭：macOS man 自带，nix-darwin 建 /share/man 意义有限，省构建产物。
  # 【对抗结论】darwin 侧影响极小且非必需，故精简移除此段（原服务器侧策略不适用 darwin）。
}
