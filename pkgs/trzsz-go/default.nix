{
  lib,
  buildGoModule,
  sources,
}: let
  source = sources.trzsz;
in
  buildGoModule rec {
    # https://github.com/trzsz/trzsz-go
    pname = "trzsz-go";
    inherit (source) version src;

    # NOTE: trzsz-go v1.2.0 需要开启 proxyVendor 并显式清理上游 vendor。
    # 这个组合与参考实现一致，能稳定复现依赖树。
    vendorHash = "sha256-xodZBTZaCOQiT2G7KzM7XlsSq8K8nnBAvL3uH5OCC5s=";
    proxyVendor = true;

    preBuild = ''
      rm -rf vendor
    '';

    env.CGO_ENABLED = 0;

    subPackages = [
      "cmd/trz"
      "cmd/tsz"
      "cmd/trzsz"
    ];

    meta = with lib; {
      description = "Simple file transfer tools, similar to rz/sz";
      homepage = "https://github.com/trzsz/trzsz-go";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  }
