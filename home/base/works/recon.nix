{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.works.recon;
in
{
  options.modules.works.recon.enable =
    lib.mkEnableOption "recon tools (nmap / naabu / subfinder / httpx / dnsx)";

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      # 信息收集
      nmap

      # 端口扫描工具
      naabu

      # 内网扫描工具
      fscan

      subfinder

      httpx

      dnsx
      gau
    ]
  );
}
