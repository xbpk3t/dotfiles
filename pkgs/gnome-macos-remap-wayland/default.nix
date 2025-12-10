{
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gnome-macos-remap-wayland";
  version = "unstable-2025-12-10";

  src = fetchFromGitHub {
    owner = "petrstepanov";
    repo = "gnome-macos-remap-wayland";
    rev = "90c82cc75b97b773a5d76a2f5752e3bd16d3e117";
    hash = "sha256-ygsF7uAXi8XVQ5NMisfht/QA0pqjJ+1Rcyjxt+Sxr6E=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    dest=$out/share/gnome-macos-remap-wayland
    mkdir -p "$dest"
    cp -r README.md config.yml install.sh uninstall.sh gnome-macos-remap.service bin resources "$dest"

    # Avoid littering the real home during install; use a temp dir instead of ~/Downloads.
    substituteInPlace "$dest/install.sh" \
      --replace "mkdir -p ~/Downloads && cd ~/Downloads" 'tmpdir=$(mktemp -d) && cd "$tmpdir"'

    mkdir -p $out/bin
    cat > $out/bin/gnome-macos-remap-wayland-install <<EOF
    #!${bash}/bin/bash
    set -euo pipefail
    cd "$dest"
    exec ./install.sh "\$@"
    EOF
    chmod +x $out/bin/gnome-macos-remap-wayland-install

    runHook postInstall
  '';

  meta = with lib; {
    description = "macOS-style keybindings for GNOME/Wayland using xremap";
    homepage = "https://github.com/petrstepanov/gnome-macos-remap-wayland";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
  };
}
