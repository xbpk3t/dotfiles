{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # GPG 和加密
    gnupg
    pinentry_mac

    # 证书和密钥管理
    openssl
  ];
}
