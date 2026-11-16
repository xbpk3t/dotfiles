{ lib, fetchzip }:
let
  # 扩展自身版本与上游 release tag 是两套编号。
  extensionVersion = "1.0.27";
  upstreamVersion = "2.0.3";
in
fetchzip {
  name = "opencli-extension-${extensionVersion}";

  # 上游 release 直接给 Chrome MV3 扩展 zip；升级：改两个版本号 + hash。
  # zip 是扁平结构（manifest.json 在根），fetchzip 不能 strip。
  url = "https://github.com/jackwener/OpenCLI/releases/download/v${upstreamVersion}/opencli-extension-v${extensionVersion}.zip";
  hash = "sha256-RCdmNys9rI/8e8jG9WVTNw6bOsnY5vyhCZ0gxWAwj9M=";
  stripRoot = false;

  meta = with lib; {
    description = "OpenCLI Browser Bridge Chrome extension";
    homepage = "https://github.com/jackwener/OpenCLI";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
