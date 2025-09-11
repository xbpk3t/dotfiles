# Cross-platform shared package management
# Contains packages common to all platforms but not in minimal set
# Organized by category in a single systemPackages definition
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # System information
    fastfetch

    # Basic utilities
    git
    curl
    wget
    vim
    htop
    tree
    unzip

    # Modern replacements
    bat # better cat
    fd # better find
    ripgrep # better grep

    # System utilities
    rsync
    screen

    # Development tools
    gcc
    gnumake
    cmake

    # Archive and file tools
    zip
    dos2unix

    # Security tools
    openssl

    # Version control and collaboration
    gh # GitHub CLI

    # Data processing tools
    jq
    yq
    dateutils # 操作日期和时间表达式 dateadd、datediff、strptime
  ];

  # Platform-specific package additions will be handled in platform modules
}
