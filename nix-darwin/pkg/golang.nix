{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    go
    gotools # goimports

    gum

    gofumpt
    golangci-lint
    gosec

    protoc-gen-go
    protoc-gen-go-grpc
    gopls # https://github.com/golang/tools includes modernize
    golines # https://github.com/segmentio/golines
    goimports-reviser

    cobra-cli
    nilaway
    go-swag # = swaggo/swag
    goreleaser

    go-mockery # https://github.com/vektra/mockery

    templ # https://github.com/a-h/templ
    go-migrate # https://github.com/golang-migrate/migrate

    gomodifytags # https://github.com/fatih/gomodifytags
  ];
}
