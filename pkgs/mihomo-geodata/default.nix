{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation {
  pname = "mihomo-geodata";
  version = "latest";

  # mihomo 的 GEOIP,CN 规则需要 Country.mmdb。VPS 在拿到代理前无法从 GitHub
  # 下载该文件（鸡生蛋），所以这里把 MetaCubeX 的 mmdb 固定进 Nix store。
  # 升级：更新 hash（nix store prefetch-file <url>）。
  src = fetchurl {
    url = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb";
    hash = "sha256-u+26bvhYTEhONaze5BU+z0vJql4isl05gocOweeA9oE=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm644 $src $out/share/mihomo/Country.mmdb
  '';

  meta = with lib; {
    description = "Mihomo country MMDB geodata (MetaCubeX meta-rules-dat)";
    homepage = "https://github.com/MetaCubeX/meta-rules-dat";
    platforms = platforms.all;
  };
}
