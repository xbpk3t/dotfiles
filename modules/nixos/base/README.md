## modules/nixos/base

本模块只放“所有机器都应一致”的基线：语言/时区、logind、zram/oom、nix 工具链、通用用户/组等。


可以保留在 base 的

- i18n.nix、logind.nix、shell.nix（通用 shell/补全）、nix-tools.nix、user-
  group.nix、zram.nix（如所有机器都启用 swap/zram）。
