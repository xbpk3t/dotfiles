# Cross-platform package management
# Migrated from ansible/roles/common/tasks/packages.yml
{ pkgs, lib, ... }:

{
  # Common packages across all platforms
  # Equivalent to ansible common_packages + system_packages
  environment.systemPackages = with pkgs; [
    # Basic utilities (from ansible common_packages)
    git
    curl
    wget
    vim
    htop
    tree
    unzip
    rsync
    screen

    # Development tools
    gcc
    gnumake
    cmake

    # Archive tools
    zip
    dos2unix

    # Security tools
    openssl

    # Modern replacements (better than ansible versions)
    bat # better cat
    fd # better find
    ripgrep # better grep

    # GitHub CLI (from ansible packages.yml)
    gh

    # Additional useful tools
    jq
    yq

    dateutils # 操作日期和时间表达式 dateadd、datediff、strptime
  ];

  # Platform-specific package additions will be handled in platform modules
}
