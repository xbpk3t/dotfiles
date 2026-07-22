# Darwin 字体配置
#
# 跨平台字体包清单见 ../../modules/fonts.nix。
# macOS 通过 nix-darwin fonts.packages 安装到 /Library/Fonts/Nix Fonts，
# 所有原生应用（Font Book、Safari 等）均可发现。
{ pkgs, ... }:
let
  fontsData = import ../../modules/fonts.nix { inherit pkgs; };
in
{
  fonts.packages = fontsData.cross;
}
