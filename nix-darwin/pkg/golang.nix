{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Go 语言工具
    # go - 由 home-manager 管理
    gofumpt
    golangci-lint
    goreleaser
    protoc-gen-go
    protoc-gen-go-grpc
    gopls
    golines
    goimports-reviser
  ];
}
