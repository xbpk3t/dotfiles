{
  pkgs,
  lib,
  config,
  ...
}:
let
  # 同 herdr.nix 的 tomlFormat：只绑定 format 渲染器，配置本体写在 generate 的 attrset 里。
  # BleachBit 读的是 INI（不是 TOML），故用 formats.ini，不能套 tomlFormat.generate。
  iniFormat = pkgs.formats.ini { };
in
{
  home = {
    packages =
      with pkgs;
      [
        # 磁盘健康/检测
        # smartctl（smartmontools）：读/写盘的 S.M.A.R.T. 数据，支持 SATA/USB/部分 NVMe，快速健康概览、离线/短测。
        # 智能信息：smartctl -a /dev/sdX
        # 快速短测：smartctl -t short /dev/sdX && smartctl -l selftest /dev/sdX
        smartmontools

        # BleachBit：CLI/GUI 清理器（缓存、tmp、浏览器痕迹等）。
        # nixpkgs meta 含 linux + aarch64-darwin（无 x86_64-darwin）。
        # macOS 上更贴合的「应用残骸/deep clean」仍是 Mole（home/darwin/mole.nix）；
        # BleachBit 偏 FHS/浏览器 cleaner，两边可并存，场景不同。
        # 对 NixOS+Docker+Postgres 的「大头」几乎帮不上忙——那些仍用：
        #   docker system df / prune、nix-collect-garbage、journalctl --vacuum-*、SQL TRUNCATE/VACUUM
        # 包：nixpkgs bleachbit（当前 6.x），无独立 HM 模块，配置见下方 home.file。
        bleachbit
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        # nvme-cli：专为 NVMe，读取/操作 NVMe Log（smart-log、error-log）、固件下载、格式化等，信息比 smartctl 更全更准。
        # 三者是互补关系：smartctl/ nvme-cli 负责健康信息，badblocks 做面向介质的全盘扫描。
        # NVMe 健康：nvme smart-log /dev/nvme0
        nvme-cli
      ];

    # 配置路径: ~/.config/bleachbit/bleachbit.ini
    # 结构化 nix → INI（同 herdr.nix 的 pkgs.formats.toml 思路）。
    # 走 home.file（与 herdr/hunk/mole 一致），不走 xdg.configFile：
    #   - 本仓库 .config 下声明式文件的惯例是 home.file.".config/..."
    #   - 路径等价于 XDG_CONFIG_HOME/bleachbit；BleachBit Constant.options_dir 也落在这里
    # ⚠️  Nix 注释不会带入生成的 INI；运行时 bleachbit -l / -p --preset 核对。
    # 自定义 CleanerML 可放 ~/.config/bleachbit/cleaners/（personal_cleaners_dir），需要时再补。
    file.".config/bleachbit/bleachbit.ini" = {
      # 下次 switch 盖回安全 preset，防 GUI 误勾 memory/empty_space
      force = true;

      source = iniFormat.generate "bleachbit.ini" {
        # ——— 通用 ———
        bleachbit = {
          # 避免首次启动冲掉我们写的 [tree] preset
          first_start = false;
          version = "6.0.0";
          # 检查更新会打外网；VPS/无 GUI 关掉
          check_online_updates = false;
          check_beta = false;
          # 删除前不默认 shred（-o）；需要时 CLI 显式 --overwrite
          shred = false;
          exit_done = false;
          delete_confirmation = true;
          debug = false;
        };

        # shred/wipe 空闲空间时的目标；仅显式 -w/-o 时相关。
        # 指向用户 cache，避免误对 / 或数据盘 wipe。
        # homeDirectory：不要 builtins.getEnv "HOME"（pure eval 常空，跨机构建会错）。
        "list/shred_drives" = {
          "0" = "${config.home.homeDirectory}/.cache";
        };

        # ——— preset 白名单（--preset 读取 [tree]）———
        # 仅用户态 tmp/cache/trash。
        # 刻意不写的高危项：
        #   system.memory      — swapoff/擦内存，VPS 易 OOM
        #   system.empty_space — 覆写空闲空间，极慢且不腾「已用」
        #   journald.clean     — 源码固定 --vacuum-size=1，过狠；用手写 journalctl --vacuum-*
        #   apt.*/dnf.*/pacman — NixOS 无对应路径；macOS 亦无关
        #   *.passwords / bash.history — 隐私/运维痕迹，按需手动
        tree = {
          "system.tmp" = true;
          "system.cache" = true;
          "system.trash" = true;
        };
      };
    };

    # 对齐 mole.nix 的 moc/mop：永远先 preview，再显式 clean。
    # bbc  = preview preset（只看不删）
    # bbcc = clean preset（真删，受上方 [tree] 白名单约束）
    # bbl  = 列出全部 cleaner.option
    # 不要做「--all-but-warning」类 alias，避免误开 system.memory / empty_space。
    shellAliases = {
      "bbc" = "bleachbit -p --preset";
      "bbcc" = "bleachbit -c --preset";
      "bbl" = "bleachbit -l";
    };
  };

}
