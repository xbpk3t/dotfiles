{
  lib,
  sources,
  makeWrapper,
  nodejs_22,
  stdenvNoCC,
}: let
  source = sources.chrome-devtools-mcp;
in
  stdenvNoCC.mkDerivation rec {

    # NOTE: 注意如果直接用 brew install chrome-devtools-mcp 或者 npx global install 都可以直接安装该pkg，但是为了便于多端复用，所以打个nixpkgs
    # https://formulae.brew.sh/formula/chrome-devtools-mcp
    # https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/skills/chrome-devtools-cli/references/installation.md
    pname = "chrome-devtools-mcp";
    inherit (source) version src;

    nativeBuildInputs = [makeWrapper];
    sourceRoot = "package";

    # source metadata 由 nvfetcher 统一生成；这里保留 builder 语义。
    # Why:
    # - 按仓库里的打包流程图，这个包更适合直接消费已发布产物，而不是重新跑一遍 npm build；
    # - upstream npm tarball 已经包含 `build/src/bin/*.js`，属于可直接执行的发布结果；
    # - `nvfetcher` 对 URL source 默认生成 `fetchurl`，这里显式解包 `.tgz`，把“获取 source”和“如何安装”分开。
    unpackPhase = ''
      runHook preUnpack
      tar -xzf "$src"
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      install -dm755 "$out/libexec/${pname}" "$out/bin"
      cp -r build LICENSE package.json "$out/libexec/${pname}/"

      makeWrapper ${lib.getExe nodejs_22} "$out/bin/chrome-devtools-mcp" \
        --add-flags "$out/libexec/${pname}/build/src/bin/chrome-devtools-mcp.js" \
        --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS 1 \
        --set CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS 1

      makeWrapper ${lib.getExe nodejs_22} "$out/bin/chrome-devtools" \
        --add-flags "$out/libexec/${pname}/build/src/bin/chrome-devtools.js" \
        --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS 1 \
        --set CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS 1

      runHook postInstall
    '';

    meta = with lib; {
      description = "Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      downloadPage = "https://www.npmjs.com/package/chrome-devtools-mcp";
      license = licenses.asl20;
      mainProgram = "chrome-devtools-mcp";
      platforms = platforms.unix;
    };
  }
