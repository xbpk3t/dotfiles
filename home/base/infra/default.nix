{
  mylib,
  ...
}:
{
  # 所有包已拆解到各自归属模块：
  #   curl/wget/tree/file/which/screen → home/base/DX/default.nix
  #   zip/unzip/p7zip/xz/zstd          → 由 ouch-rar 替代（home/base/devops/default.nix）
  #   gnupg/sops/age                   → home/base/devops/secrets.nix
  #   openssh                          → home/base/devops/ssh.nix
  #   openssl                          → home/core/infra/networking.nix

  imports = mylib.scanPaths ./.;
}
