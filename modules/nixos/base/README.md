## modules/nixos/base

本模块只放“所有机器都应一致”的基线：语言/时区、logind、zram/oom、nix 工具链、通用用户/组等。


可以保留在 base 的

- i18n.nix、logind.nix、shell.nix（通用 shell/补全）、nix-tools.nix、user-
  group.nix、zram.nix（如所有机器都启用 swap/zram）。


- 注意 common 和 server/desktop 里面的配置需要完全正交。具体来说，某个配置项，如果在common里出现了，那么就不应该再出现在 server or desktop里。而 server 和 desktop 里的配置项是可以重复的。
