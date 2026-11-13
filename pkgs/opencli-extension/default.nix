{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:
let
  # 扩展自身版本与上游 release tag 是两套编号。
  extensionVersion = "1.0.27";
  upstreamVersion = "2.0.3";
in
stdenv.mkDerivation {
  pname = "opencli-extension";
  version = extensionVersion;

  # 上游 release 直接给 Chrome MV3 扩展 zip；升级：改两个版本号 + hash。
  src = fetchurl {
    url = "https://github.com/jackwener/OpenCLI/releases/download/v${upstreamVersion}/opencli-extension-v${extensionVersion}.zip";
    hash = "sha256-hjbUKg/kTXujsGA9vNlYHoJpzLypUBNtDfwP/DmoohM=";
  };

  nativeBuildInputs = [ unzip ];
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    unzip $src -d $out
  '';

  meta = with lib; {
    description = "OpenCLI Browser Bridge Chrome extension";
    homepage = "https://github.com/jackwener/OpenCLI";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
