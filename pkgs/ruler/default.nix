{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "ruler";
  version = "0.3.11";

  src = fetchFromGitHub {
    owner = "intellectronica";
    repo = "ruler";
    rev = "v0.3.11";
    hash = "sha256-hktUlLmdUwSWaSJrzuNUsfsH9M4ZTMiNfvLQeu62+DU=";
  };

  npmDepsHash = "sha256-0ca7URn1SonTUazf3eA7+XOhARvn+gIs4Y41J77kYjY=";

  meta = with lib; {
    description = "Ruler — apply the same rules to all coding agents";
    homepage = "https://github.com/intellectronica/ruler";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
