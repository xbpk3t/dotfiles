{
  lib,
  rustPlatform,
  sources,
}: let
  source = sources.launchk;
in
  rustPlatform.buildRustPackage rec {
    # [intellekthq/launchk: Rust/Cursive TUI for observing launchd agents and daemons](https://github.com/intellekthq/launchk)

    pname = "launchk";
    version = lib.removePrefix "launchk-" source.version;

    inherit (source) src;

    patches = [./git.patch];

    cargoBuildFlags = ["--package" "launchk"];

    cargoHash = "sha256-k/n22Bfg857bWFl8sVhZI3YI2i9JuWmT28zN86W/ing=";

    nativeBuildInputs = [rustPlatform.bindgenHook];

    meta = with lib; {
      description = "A TUI for managing launchd services on macOS";
      homepage = "https://github.com/intellekthq/launchk";
      license = licenses.mit;
      platforms = ["aarch64-darwin"];
      mainProgram = "launchk";
    };
  }
