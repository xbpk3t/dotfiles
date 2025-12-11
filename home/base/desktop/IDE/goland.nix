{pkgs, ...}:
# Wrap GoLand so it always launches through XWayland. JetBrains still
# lacks proper IME support on native Wayland, so we strip the Wayland
# variables before delegating to the upstream launcher.
# goland-x11 = pkgs.symlinkJoin {
#   name = "goland-x11";
#   paths = [pkgs.jetbrains.goland];
#   buildInputs = [pkgs.makeWrapper];
#   postBuild = ''
#     wrapProgram $out/bin/goland \
#       --set GDK_BACKEND x11 \
#       --set QT_QPA_PLATFORM xcb \
#       --set SDL_VIDEODRIVER x11 \
#       --set XDG_SESSION_TYPE x11 \
#       --set NIXOS_OZONE_WL 0 \
#       --unset WAYLAND_DISPLAY \
#       --unset MOZ_ENABLE_WAYLAND \
#       --unset ELECTRON_OZONE_PLATFORM_HINT
#   '';
# };
{
  home.packages = with pkgs; [
    # jetbrains.goland
    goland-2025-3
  ];
}
