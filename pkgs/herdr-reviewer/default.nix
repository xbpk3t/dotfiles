{
  lib,
  sources,
  stdenv,
  fetchurl,
}:
let
  # ——— 上游源码 checkout（nvfetcher 管 source，见 nvfetcher.toml [herdr-reviewer-src]） ———
  # 只用来取 herdr-plugin.toml + herdr/（pane.sh ~400 行，手写不可行）。
  # 声明式接入下 herdr 永不执行 [[build]]（herdr 源码 cli/plugin.rs:210，
  # build 只在 `herdr plugin install` 触发；且 build 前后 manifest 必须不可变），
  # 所以 src 里只需这两个路径，install.sh 不复制、不执行。
  source = sources.herdr-reviewer-src;

  # ——— 4 平台预编译 release asset（system → asset 名） ———
  # asset 是 tar.gz（内含单文件 herdr-reviewr），sha256 sidecar = tar.gz 文件本身 hash。
  # ⚠️ 不用 fetchzip：fetchzip 递归 hash 解包内容，与 sidecar（文件 hash）不一致；
  #    用 fetchurl 验证 tar 字节 + installPhase 里 tar -xzf 解包（与上游 install.sh 同思路）。
  # URL: https://github.com/persiyanov/herdr-reviewr/releases/download/v0.29.0/herdr-reviewr-<target>.tar.gz
  assetBySystem = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-darwin" = "x86_64-apple-darwin"; # 预留
    "aarch64-linux" = "aarch64-unknown-linux-musl";
    "x86_64-linux" = "x86_64-unknown-linux-musl";
  };
  binaryHashes = {
    "aarch64-apple-darwin" = "075a295ece3a31e125af5fe9eba894b2e117f84dfc9ff630b6c2454d06d2a8e8";
    "x86_64-apple-darwin" = "bf9adfa79a7f023fb919788b6b7513e5a169198813448fbfbebe186addcd9836";
    "aarch64-unknown-linux-musl" = "a53cddad239facadeea61b3113b142e570d560e3afeead0bd418d2d931e29446";
    "x86_64-unknown-linux-musl" = "ec1b207444d36cb3c279a170d75d32f9a6f2db1c85ac5492fd77ea723b1b8135";
  };
  version = "0.29.0";
  # ——— version / asset / hash 三处同步升 ———

  system = stdenv.hostPlatform.system;
  asset =
    assetBySystem.${system}
      or (throw "herdr-reviewer: unsupported system ${system} (asset map has ${toString (builtins.attrNames assetBySystem)})");
  binaryHash =
    binaryHashes.${asset}
      or (throw "herdr-reviewer: no binary hash for asset ${asset} — release sidecar missing?");
in
stdenv.mkDerivation rec {
  # ——— 打包策略（按仓库打包流程图） ———
  # 有 release 产物 → fetchurl 直接消费（不重建 Rust，与 llm-agents packages/herdr fromBinary 同思路）：
  #   - asset 内含单文件二进制（tar -xzf 解包，见上 fetchzip 禁用说明）
  #   - manifest/pane.sh 从源码 checkout 取（pane.sh ~400 行不可手写）
  pname = "herdr-reviewer";
  inherit version;

  # ——— 二进制（当前平台，由 assetBySystem 映射） ———
  src = fetchurl {
    url = "https://github.com/persiyanov/herdr-reviewr/releases/download/v${version}/herdr-reviewr-${asset}.tar.gz";
    sha256 = binaryHash;
  };

  # ——— 插件外壳（manifest + pane.sh 来自源码 checkout） ———
  # 布局必须与上游插件根一致（manifest 相对路径依赖）：
  #   $out/plugin/herdr-plugin.toml   （根）
  #   $out/plugin/herdr/              （pane.sh 等，actions/events cwd = plugin_root）
  #   $out/plugin/bin/herdr-reviewr
  # manifest 里 pane command 是 "$HERDR_PLUGIN_ROOT/bin/herdr-reviewr"（herdr server 打开
  # pane 时注入 HERDR_PLUGIN_ROOT，env.rs plugin_path_env + panes.rs:245），
  # actions/events command 是 "bash herdr/pane.sh"（cwd = plugin_root，runtime.rs:123）——
  # 两条相对路径原样保留，不要改成绝对 store 路径（rebuild 会变）。
  pluginSrc = source.src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    # 1) 解包二进制（fetchurl 的 $src 是 tar 路径，不是目录）
    tar -xzf "$src" -C "$TMPDIR"

    # 2) 组装插件根
    mkdir -p "$out/plugin/bin" "$out/plugin/herdr"
    install -m0755 "$TMPDIR/herdr-reviewr" "$out/plugin/bin/herdr-reviewr"
    cp "${pluginSrc}/herdr-plugin.toml" "$out/plugin/herdr-plugin.toml"
    # 只拷 pane.sh（actions/events 的 cwd = plugin_root，相对路径 bash herdr/pane.sh 解析）。
    # install.sh 不拷：它是 herdr plugin install 的 [[build]] 步骤，声明式下永不执行
    # （herdr 源码 cli/plugin.rs:210，build 只在 install 触发），拷进去反而语义混乱。
    cp "${pluginSrc}/herdr/pane.sh" "$out/plugin/herdr/pane.sh"
    chmod +x "$out/plugin/herdr/pane.sh"

    # 3) 同时暴露可执行入口（与 focus-notify 的 $out/bin 对齐，便于调试/直接调用）
    mkdir -p "$out/bin"
    install -m0755 "$out/plugin/bin/herdr-reviewr" "$out/bin/herdr-reviewr"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Reviewr — herdr plugin for code review";
    homepage = "https://github.com/persiyanov/herdr-reviewr";
    license = licenses.mit;
    # 与仓库 supportedSystems（outputs/default.nix）对齐；
    # assetBySystem 缺失的平台会在这里显式 throw，而不是静默 skip。
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    mainProgram = "herdr-reviewr";
  };
}
