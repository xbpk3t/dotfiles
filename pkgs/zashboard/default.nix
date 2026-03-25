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
  src = fetchzip {
    url = "https://github.com/Zephyruso/zashboard/releases/download/v${version}/dist.zip";
    hash = "sha256-uI1BZEADLiTO/efl8OPM1s+dLotZTawdVPO5QcfzzOU=";
    stripRoot = false;
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
