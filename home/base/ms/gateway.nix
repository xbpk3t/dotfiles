{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # 注意并不打算用来启动本地 web-server，只是打算作为 caddy validate & fmt 使用
    caddy

    # gRPC API 调试 CLI
    grpcurl
    buf

    # tags(desc): 代码生成 > gRPC > Protobuf
    protoc-gen-go-grpc
  ];
}
