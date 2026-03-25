{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "zashboard";
  version = "2.8.0";

  # Generated from:
  #   nurl https://github.com/Zephyruso/zashboard/releases/download/v2.8.0/dist.zip
  #
  # We package the published static assets instead of rebuilding the Vue app.
  # This keeps the derivation tiny and avoids maintaining pnpm-specific plumbing.
  # [2026-03-25] 移除掉 skipRoot = false. 因为 dist.zip 里有顶层 dist/ 目录，但 pkgs/zashboard/default.nix 里写了 stripRoot = false，导致 fetchzip 输出把 dist/ 也带进去了
  #  - 错的：$out/dist/...，哈希 sha256-2ZpCmexVlb533uvYsbPL4Qmw+5G7ShqDb2i5IOcVLRM=
  #  - 对的：$out/...，哈希 sha256-uI1BZEADLiTO/efl8OPM1s+dLotZTawdVPO5QcfzzOU=
  src = fetchzip {
    url = "https://github.com/Zephyruso/zashboard/releases/download/v${version}/dist.zip";
    hash = "sha256-uI1BZEADLiTO/efl8OPM1s+dLotZTawdVPO5QcfzzOU=";
  };

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
