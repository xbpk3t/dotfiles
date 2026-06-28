{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "1.3.4";
  sys = stdenvNoCC.hostPlatform.system;

  # cc-connect 上游提供预编译 Go 单二进制。
  # 按 system 分流 URL 与 hash；新增平台只需补上对应条目。
  # nvfetcher 配置保留了 version tracking，但实际构建不依赖 generated.nix。
  platforms = {
    x86_64-linux = {
      url = "https://github.com/chenhg5/cc-connect/releases/download/v${version}/cc-connect-v${version}-linux-amd64";
      hash = "sha256-hqjADSP3YpaPgZr7yIInbZJOZowf1rTRL3HUdu8kyZc=";
    };
    aarch64-linux = {
      url = "https://github.com/chenhg5/cc-connect/releases/download/v${version}/cc-connect-v${version}-linux-arm64";
      hash = "sha256-EPJCLRgz2LDICXARNqvMu9/Mk6oRtbJl8DRA3rUMABA=";
    };
    x86_64-darwin = {
      url = "https://github.com/chenhg5/cc-connect/releases/download/v${version}/cc-connect-v${version}-darwin-amd64";
      hash = "sha256-RHlJm9c5+Y/PObZRcE2nTvp6feBwDEfv/K6ZHWGdsc0=";
    };
    aarch64-darwin = {
      url = "https://github.com/chenhg5/cc-connect/releases/download/v${version}/cc-connect-v${version}-darwin-arm64";
      hash = "sha256-AEoVo7dQOe9CC2El+uaRTrmUV76EdUpDEuAtZosvxwQ=";
    };
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "cc-connect";
  inherit version;

  src = fetchurl (platforms.${sys} or (throw "${pname}: unsupported system: ${sys}"));

  # 预编译二进制不是压缩包，不需要 unpack
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -m755 -D "$src" "$out/bin/cc-connect"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Bridge local AI coding agents to messaging platforms";
    longDescription = ''
      cc-connect bridges local AI coding agents (Claude Code, Cursor, Gemini CLI, etc.)
      to messaging platforms (Feishu, DingTalk, Slack, Telegram, Discord, etc.).
      It runs as a local daemon and forwards agent output to IM platforms,
      allowing remote control of AI agents from your phone.
    '';
    homepage = "https://github.com/chenhg5/cc-connect";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "cc-connect";
  };
}
