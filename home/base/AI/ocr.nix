{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.ocr;
in
{
  # host:
  #   modules.AI.ocr.enable = true;
  #
  # Package: inputs.llm-agents（Go from-source build；cache.numtide.com 有缓存）。
  # llm-agents 里包名是 open-code-review，安装后的二进制名是 ocr。
  # 首次使用需要配置 provider：ocr config provider（或 ocr config set ...）。
  options.modules.AI.ocr = with lib; {
    enable = mkEnableOption "OpenCodeReview (ocr) AI code review CLI";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.open-code-review
    ];
  };
}
