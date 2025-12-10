{
  fetchurl,
  jetbrains,
  ...
}: let
  srcPath = "file:///home/luck/Desktop/dotfiles/goland-2025.3.tar.gz";
  srcHash = "sha256-YVGFYobqVG64r5rrAldyzua9VxNPRUlKgY6NogqGkcY=";
in
  jetbrains.goland.overrideAttrs (old: {
    version = "2025.3";
    src = fetchurl {
      url = srcPath;
      hash = srcHash;
    };

    # Inject Wayland + fcitx5 defaults. Keep upstream postFixup if present.
    postFixup =
      (old.postFixup or "")
      + ''
        wrapProgram $out/bin/goland \
          --set GTK_IM_MODULE fcitx \
          --set QT_IM_MODULE fcitx \
          --set XMODIFIERS "@im=fcitx" \
          --set IBUS_ENABLE_SYNC_MODE 1 \
          --set JDK_JAVA_OPTIONS "-Dawt.toolkit.name=WLToolkit"
      '';
  })
