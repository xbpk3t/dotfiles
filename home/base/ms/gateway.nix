{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.ms.gateway;
in
{
  options.modules.ms.gateway = {
    enable = lib.mkEnableOption "API gateway tools";

    caddy.enable = lib.mkEnableOption "Caddy (validate/fmt)";

    grpc.enable = lib.mkEnableOption "gRPC tooling (grpcurl / buf / protoc-gen-go-grpc)";
  };

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    lib.optionals cfg.caddy.enable [
      # 注意并不打算用来启动本地 web-server，只是打算作为 caddy validate & fmt 使用
      caddy
    ]
    ++ lib.optionals cfg.grpc.enable [
      # gRPC API 调试 CLI
      grpcurl
      buf

      # tags(desc): 代码生成 > gRPC > Protobuf
      protoc-gen-go-grpc
    ]
  );
}
