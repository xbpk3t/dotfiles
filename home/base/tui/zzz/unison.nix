{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.sync.unison;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in {
  # MAYBE: [2026-04-06] 考虑用 mutagen or unison
  # 目前使用 unison 而非更好用的 mutagen 就是因为 unison本身提供了hm支持，但是 unison 的hm只支持linux（本质仍然是hm只处理了systemd，不兼容launchd），darwin仍然需要自己手动处理，之后再看怎么处理。
  # 目前处理方案有3种：
  #  1. 保持现在这版
  #     只在 Linux host 启用 modules.sync.unison。
  #     这是最省事、最稳的方案。
  #  2. Darwin 上只装包，不做 service
  #     也就是 macOS 机器装 pkgs.unison，但不通过 HM services.unison 管理。
  #     你手工跑 unison，或者自己单独配 launchd。
  #  3. 我们自己补一层 Darwin 版实现
  #     在你的 unison.nix 里继续保留 pairs 这套声明，然后：
  #      - Linux 映射到 services.unison
  #      - Darwin 映射到 launchd.agents
  #        这样语义最统一，但你就不再是“纯复用 HM upstream 模块”，而是在仓库里自己维护一套跨平台包
  #        装。

  # Mutagen 比 Unison 更强的点：
  # 1. 实时同步体验更现代，更适合 remote development / container development。
  # 2. 在 SSH/remote endpoint 场景下，通常更低延迟。
  # 3. 更偏向“本地改，远端立刻可见”的 development workflow。
  #
  # 这里仍然选择 Unison：
  # 1. 当前仓库更看重“具体同步哪些 folder 能直接在 host 层 declarative 配置”。
  # 2. Home Manager 已经原生提供 services.unison，Nix 集成明显更顺。
  # 3. 当前需求是维护少量明确的双向同步 pair，不是优化 remote development latency。
  #
  # 额外注意：
  # 1. services.unison 是 Linux-only，Darwin host 不应启用。
  # 2. `roots` 必须正好两个，分别是这一组同步 pair 的两个 endpoint。
  # 3. endpoint 可以是 local absolute path，也可以是 remote SSH URL。
  # 4. remote endpoint 推荐写成 ssh://user@host//absolute/path，避免相对路径歧义。
  #
  # host 侧调用示例：
  # modules.sync.unison = {
  #   enable = true;
  #   pairs.goland-scratches = {
  #     roots = [
  #       "/home/luck/.local/share/JetBrains/GoLand/scratches"
  #       "ssh://luck@homelab//home/luck/.local/share/JetBrains/GoLand/scratches"
  #     ];
  #     commandOptions = {
  #       repeat = "watch";
  #       sshcmd = "${pkgs.openssh}/bin/ssh";
  #     };
  #   };
  # };

  options.modules.sync.unison = with lib; {
    enable = mkEnableOption "Declarative Unison sync pairs";

    pairs = mkOption {
      type = with types; attrsOf attrs;
      default = {};
      description = "Direct passthrough to Home Manager services.unison.pairs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.unison = {
      # 注意只支持linux
      enable = isLinux;
      pairs = lib.mkIf isLinux cfg.pairs;
    };
  };
}
