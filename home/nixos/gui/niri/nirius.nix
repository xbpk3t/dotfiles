{
  lib,
  fetchFromSourcehut,
  rustPlatform,
}:
# https://git.sr.ht/~tsdh/nirius
# https://github.com/jtojnar/nixpkgs/blob/master/pkgs/by-name/ni/nirius/package.nix
rustPlatform.buildRustPackage rec {
  pname = "nirius";
  version = "0.4.1";

  src = fetchFromSourcehut {
    owner = "~tsdh";
    repo = "nirius";
    rev = "nirius-${version}";
    sha256 = "sha256-w4ZNlCXtyRDGnQQFkxAIibc4TvQ8BSZsKIFGaNOrK94=";
  };

  cargoHash = "sha256-8Io3edeWvgb7LXEmXG2l2ESTLBeltHliyG8dD71j2K0=";

  meta = with lib; {
    description = "Utility commands for the niri wayland compositor";
    mainProgram = "nirius";
    homepage = "https://git.sr.ht/~tsdh/nirius";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [tylerjl];
  };
}
