{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "zashboard";
  version = "2.8.0";

  src = fetchFromGitHub {
    owner = "Zephyruso";
    repo = "zashboard";
    rev = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = lib.fakeHash;
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/zashboard
    cp -r dist/* $out/share/zashboard/
    runHook postInstall
  '';

  meta = with lib; {
    description = "A dashboard using Clash API";
    homepage = "https://github.com/Zephyruso/zashboard";
    license = licenses.mit;
    platforms = platforms.all;
  };
})
