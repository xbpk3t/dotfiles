{
  lib,
  sources,
  stdenvNoCC,
  unzip,
}: let
  source = sources.zashboard;
in
  stdenvNoCC.mkDerivation rec {
    pname = "zashboard";
    inherit (source) version src;
    nativeBuildInputs = [unzip];
    sourceRoot = "dist";

    # We package the published static assets instead of rebuilding the Vue app.
    # This keeps the derivation tiny and avoids maintaining pnpm-specific plumbing.
    #
    # source metadata 由 nvfetcher 统一生成。
    # Why: release version / hash 的升级属于机械更新，没必要继续手写维护。
    # 注意：nvfetcher 对 url source 默认生成 fetchurl。
    # 这里显式加 unzip + sourceRoot = "dist"，把 raw zip 还原成原先 fetchzip 的目录语义。
    installPhase = ''
      runHook preInstall
      install -dm755 "$out/share/zashboard"
      cp -r ./* "$out/share/zashboard/"
      runHook postInstall
    '';

    meta = with lib; {
      description = "A dashboard using Clash API";
      homepage = "https://github.com/Zephyruso/zashboard";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
