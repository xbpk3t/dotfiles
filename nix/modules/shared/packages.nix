# Cross-platform shared package management
# Contains packages common to all platforms but not in minimal set
# Organized by category in a single systemPackages definition
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Basic utilities
    curl
    wget

    tree

    zip
    unzip

    # System utilities
    screen

    # Development tools
    gcc
    gnumake
    cmake

    dateutils # 操作日期和时间表达式 dateadd、datediff、strptime
  ];
}
