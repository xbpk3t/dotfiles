{ pkgs, ... }: {
  # 系统级包 - 从 Homebrew formulae 迁移
  environment.systemPackages = with pkgs; [
    # 基础工具
    ack
    ansible
    ansible-lint
    autocorrect
    automake
    bat
    bfg-repo-cleaner
    binutils
    cabextract
    carthage
    clang-tools
    cloc
    wrangler
    cmake
    colima
    direnv
    docker
    docker-compose
    docker-credential-helpers
    dotbot
    nodePackages.eslint
    fastfetch
    fcrackzip
    ffmpeg
    fish
    fping
    gcc
    gh
    git
    git-lfs
    git-quick-stats
    gitleaks
    gitlint
    go-task
    gobject-introspection
    gofumpt
    golangci-lint
    goreleaser
    graphviz
    grpcurl
    hadolint
    helmfile
    htop
    httpie
    imagemagick
    inetutils
    jq
    jump
    kompose
    kube-linter
    kubectx
    libimobiledevice
    libpcap
    lux
    lychee
    markdownlint-cli
    minikube
    mockery
    mosh
    mplayer
    mysql80
    nasm
    ncdu
    nmap
    optipng
    p7zip
    pandoc
    pgloader
    pipx
    pngquant
    nodePackages.pnpm
    pre-commit
    protoc-gen-go
    protoc-gen-go-grpc
    python3Packages.pygments
    rclone
    rustup
    shellcheck
    speedtest-cli
    sshpass
    subfinder
    talisman
    silver-searcher
    tree
    trufflehog
    urlscan
    uv
    vegeta
    viddy
    wget
    yamllint
    yarn
    yq
    # Android tools (from casks)
    android-tools
  ];

  # 保留部分 GUI 应用使用 Homebrew
  homebrew = {
    enable = true;
    casks = [
      "alfred"
      "goland"
      "google-chrome"
      "hammerspoon"
      "hyperconnect"
      "mihomo-party"
      "tencent-lemon"
      "wechat"
    ];
  };

  # 系统配置
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # 启用 fish shell
  programs.fish.enable = true;

  # 系统版本
  system.stateVersion = 6;
}
