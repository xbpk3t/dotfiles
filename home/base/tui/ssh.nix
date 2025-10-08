{pkgs, ...}: {
  home.packages = with pkgs; [
    sshs
    termscp
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # 禁用默认配置，手动设置

    matchBlocks = {
      "*" = {
        # 全局选项移到 matchBlocks."*" 下
        addKeysToAgent = "yes";

        # Connection multiplexing
        controlMaster = "auto";
        controlPath = "/tmp/%r@%h:%p";
        controlPersist = "yes";

        # Hash known hosts for privacy
        hashKnownHosts = true;

        # 连接保持活动设置
        serverAliveInterval = 15;
        serverAliveCountMax = 6;

        # 慢连接压缩
        compression = true;

        # 启用详细日志记录以进行调试（如有需要取消注释）
        # LogLevel VERBOSE

        # 转发SSH代理
        forwardAgent = true;

        # 启用X11转发（如需要）
        forwardX11 = false;
      };

      "github.com" = {
        # "Using SSH over the HTTPS port for GitHub"
        # "(port 22 is banned by some proxies / firewalls)"
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        identityFile = "/etc/sk/ssh/github/private_key";
        identitiesOnly = true;
      };

      "vps" = {
        hostname = "47.79.17.202";
        user = "root";
        port = 22;
        identityFile = "/etc/sk/ssh/vps/private_key";
      };
    };
  };
}
