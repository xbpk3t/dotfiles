{
  lib,
  stdenv,
  autoPatchelfHook,
  zlib,
  apm-bin-x86_64-linux,
  apm-bin-aarch64-linux,
  apm-bin-aarch64-darwin,
  apm-bin-x86_64-darwin,
}:
let
  sources = {
    x86_64-linux = apm-bin-x86_64-linux;
    aarch64-linux = apm-bin-aarch64-linux;
    aarch64-darwin = apm-bin-aarch64-darwin;
    x86_64-darwin = apm-bin-x86_64-darwin;
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "apm-bin: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "apm-bin";
  inherit (source) version src;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ zlib ];

  # PyInstaller bundle: the bootloader and _internal must stay together.
  dontStrip = true;

  unpackPhase = "tar -xzf $src --strip-components=1";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -a apm _internal $out/bin/

    runHook postInstall
  '';

  meta = {
    description = "Agent Package Manager (official standalone release)";
    homepage = "https://github.com/microsoft/apm";
    license = lib.licenses.mit;
    mainProgram = "apm";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
