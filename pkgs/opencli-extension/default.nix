{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "opencli-extension";
  version = "1.0.27";

  # 上游 release 直接给 Chrome MV3 扩展 zip；升级：改 version + hash。
  src = fetchurl {
    url = "https://github.com/jackwener/OpenCLI/releases/download/v2.0.3/opencli-extension-v${finalAttrs.version}.zip";
    hash = "sha256-hjbUKg/kTXujsGA9vNlYHoJpzLypUBNtDfwP/DmoohM=";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = "unzip $src -d .";

  installPhase = ''
    mkdir -p $out
    cp -a ./. $out/
  '';

  meta = with lib; {
    description = "OpenCLI Browser Bridge Chrome extension";
    homepage = "https://github.com/jackwener/OpenCLI";
    license = licenses.mit;
    platforms = platforms.all;
  };
})
