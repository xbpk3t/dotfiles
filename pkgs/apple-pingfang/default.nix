{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (_finalAttrs: rec {
  pname = "apple-pingfang";
  version = "2024-07-02";

  src = fetchFromGitHub {
    owner = "ZWolken";
    repo = "PingFang";
    rev = "92cad0e8cfce61ddae4a220739a250d95f22fb78";
    hash = "sha256-kfNTzV1ehFU3u8+0G0n6tsOBQz/TeVyP+OtlASPkfcw=";
  };

  installPhase = ''
    runHook preInstall

    install -dm755 "$out/share/fonts/opentype"
    install -dm755 "$out/share/fonts/truetype"

    for font in *.otf; do
      install -Dm444 "$font" "$out/share/fonts/opentype/$font"
    done

    install -Dm444 TrueType_Collection_format/PingFang.ttc \
      "$out/share/fonts/truetype/PingFang.ttc"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apple PingFang Chinese font family (OTF and TTC)";
    homepage = "https://github.com/ZWolken/PingFang";
    license = licenses.unfreeRedistributable;
    platforms = platforms.all;
  };
})
