{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dagu";
  version = "2.26.0";

  # 上游 release 直接给静态链接的二进制（tarball 根目录只有 dagu + LICENSE/README）。
  # 升级：改 version，更新 hash（nix store prefetch-file <url>）。
  src = fetchurl {
    url = "https://github.com/dagucloud/dagu/releases/download/v${finalAttrs.version}/dagu_${finalAttrs.version}_linux_amd64.tar.gz";
    hash = "sha256-KxyrXbq3x9xmB9gH4sv2WX8m1aXQlELiwqvP4ay/nmg=";
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 dagu $out/bin/dagu
  '';

  meta = with lib; {
    description = "DAG-based workflow engine";
    homepage = "https://github.com/dagucloud/dagu";
    license = licenses.gpl3Plus;
    mainProgram = "dagu";
    platforms = [ "x86_64-linux" ];
  };
})
