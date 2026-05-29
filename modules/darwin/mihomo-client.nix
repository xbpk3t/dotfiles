{
  config,
  pkgs,
  lib,
  mylib,
  userMeta,
  ...
}:
with lib; let
  cfg = config.modules.networking.mihomo;
  username = userMeta.username;
  client = import ../../lib/mihomo/client-config.nix {
    inherit
      config
      mylib
      lib
      pkgs
      ;
    inherit (cfg) wildUrl;
    selfProviderTemplateName = "mihomo-self-provider.yaml";
  };
  configPath = config.sops.templates."mihomo-client.yaml".path;
  # writeShellApplication 会把 runtimeInputs 列出来的所有 derivation 通过 PATH
  # 前置注入，且整体打包成一个 store path。launchd plist 只引用 launcher 一个
  # store path，运行时闭包（mihomo + coreutils + bash）由 launcher derivation
  # 自动维护，不会出现"plist 引 N 个 path、任一被 GC 即挂"的 race。
  #
  # Why 显式列 coreutils：launcher 里用到 mkdir / rm，虽然 launchd plist PATH
  # 也带了 /bin，但显式列出来让 nix 帮忙做 hermetic check（writeShellApplication
  # 内部跑 shellcheck），出现未声明命令时 build 阶段就会报错而不是 runtime。
  mihomoLauncher = pkgs.writeShellApplication {
    name = "mihomo-tun-launcher";
    runtimeInputs = with pkgs; [mihomo coreutils];
    text = ''
      mkdir -p /var/lib/mihomo/providers
      rm -f /var/lib/mihomo/providers/self.yaml
      exec mihomo -d /var/lib/mihomo -f "$1"
    '';
  };

  wildUpdater = pkgs.writeShellApplication {
    name = "mihomo-wild-updater";
    runtimeInputs = with pkgs; [coreutils curl];
    text = ''
      mkdir -p /var/lib/mihomo/providers
      tmp="$(mktemp /var/lib/mihomo/providers/wild-fetched.yaml.XXXXXX)"
      trap 'rm -f "$tmp"' EXIT

      if curl -fsSLo "$tmp" --connect-timeout 15 --max-time 60 "${cfg.wildUrl}"; then
        if [ -s "$tmp" ]; then
          chmod 0644 "$tmp"
          mv "$tmp" /var/lib/mihomo/providers/wild-fetched.yaml
          trap - EXIT
          exit 0
        fi
        echo "wild provider fetch returned empty content" >&2
      fi

      exit 1
    '';
  };
in {
  options.modules.networking.mihomo = {
    enable = mkEnableOption "mihomo TUN proxy daemon";
    wildUrl = mkOption {
      type = lib.types.str;
      default = "http://${mylib.inventory."nixos-vps"."nixos-vps-dev".tailscale.ip}:3001/admin/download/collection/wild?target=ClashMeta";
      description = ''
        Sub-Store wild provider subscription URL。
        默认指向 nixos-vps-dev 的 sub-store（tailscale 内网，admin path 固定 /admin）。
      '';
    };
  };

  config = mkIf cfg.enable {
    # sops 渲染含 secret 的 YAML config，不进 /nix/store
    sops.templates."mihomo-client.yaml".content = client.templatesContent;
    sops.templates."mihomo-self-provider.yaml".content = client.selfProviderContent;

    # config 已在构建时转为 YAML，sops 渲染后由 launcher 直接 exec mihomo
    # Metacubexd 作为 Web UI 通过 external-controller 端口管理配置
    launchd.daemons.mihomo-tun = {
      serviceConfig = {
        Label = "local.mihomo.tun";
        ProgramArguments = [
          "${mihomoLauncher}/bin/mihomo-tun-launcher"
          configPath
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        ThrottleInterval = 10;
        WorkingDirectory = "/var/lib/mihomo";
        StandardOutPath = "/Users/${username}/Library/Logs/mihomo.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/mihomo.log";
        EnvironmentVariables = {
          # daemon 以 root 跑，不需要 per-user profile；保持系统级 PATH 即可。
          # writeShellApplication 内部还会前置注入 runtimeInputs，所以这里只作
          # 兜底（保证 launcher 自己能被 launchd exec 起来）。
          PATH = "/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          # mihomo 默认只允许 working dir / homedir / SAFE_PATHS 下的路径作为
          # file provider 源或 external-ui 来源。把 metacubexd（UI）和
          # sops 渲染目录都加进来。
          SAFE_PATHS = "${pkgs.metacubexd}:/run/secrets/rendered";
        };
      };
    };

    # 独立 system daemon：后台 best-effort 拉取 wild provider 数据。
    # 不和 mihomo-tun 启动路径混在一起，避免 Tailscale 内网 URL 不可达时阻塞 TUN。
    # 成功时原子替换缓存；失败只留下日志/exit code，保留旧缓存并不影响 mihomo。
    launchd.daemons.mihomo-wild-updater = {
      serviceConfig = {
        Label = "local.mihomo.wild-updater";
        ProgramArguments = [
          "${wildUpdater}/bin/mihomo-wild-updater"
        ];
        RunAtLoad = true;
        StartInterval = 1800;
        WorkingDirectory = "/var/lib/mihomo";
        StandardOutPath = "/Users/${username}/Library/Logs/mihomo-wild-updater.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/mihomo-wild-updater.log";
      };
    };
  };
}
