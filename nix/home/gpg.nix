_: {
  programs.gpg = {
    enable = true;
    settings = {
      # 基本设置
      default-key = "yyzw@live.com";

      # 密钥服务器设置
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "auto-key-retrieve";

      # 算法偏好
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";

      # 默认偏好
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      # 证书摘要算法
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";

      # 字符集
      charset = "utf-8";

      # 显示设置
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
    pinentry.package = null; # 使用系统默认的 pinentry
  };
}
