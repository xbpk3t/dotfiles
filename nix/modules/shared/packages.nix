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
    tmux

    # Network tools
    net-tools
    telnet
    traceroute
    bind # for dig, nslookup

    # System monitoring
    iotop
    sysstat
    lsof

    # Development tools
    gcc
    gnumake
    cmake

    # Archive tools
    zip
    dos2unix

    # Security tools
    openssl

    # Process management
    psmisc # killall, pstree, etc

    # Modern replacements (better than ansible versions)
    bat # better cat
    fd # better find
    ripgrep # better grep
    exa # better ls

    # GitHub CLI (from ansible packages.yml)
    gh

    # Additional useful tools
    jq
    yq

    # Container tools
    podman # docker alternative
    podman-compose
  ];

  # Platform-specific package additions will be handled in platform modules
}
