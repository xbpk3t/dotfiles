{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    # duti 用来管理 macOS 默认 app / UTI / URL scheme 关联，是 macOS 上管理默认应用关联的 CLI
    # osascript -e 'id of app "Ghostty"'
    ## 返回 com.mitchellh.ghostty
    # 把 默认Terminal 修改为 Terminal.app
    ## duti -s com.apple.Terminal public.unix-executable all
    ## duti -d public.unix-executable
    duti
  ];

  # 起因: [macOS Finder菜单 在终端中打开 替换为ghostty - 开发调优 - LINUX DO](https://linux.do/t/topic/2081199/4)
  # 为啥应该这些放到 hm 而非 modules里？
  ## 不推荐放到 modules里，因为这个操作和 system.defaults 不是一回事。因为duti改的是 当前用户的默认关联应用，而非 system.defaults 这个系统级。并且如果用后者，反而会更麻烦。
  # 多个类似操作是放进同一个 activation，还是并列多个 activation？
  ## 同类操作放到同一个 activation 里，比如说都是用来设置 DefaultApps 的，那么就都放到这里。如果有 clearSomeCache、linkExternalConfig 等其他操作再拆到其他 activation
  home.activation.setDefaultApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # 设置 ghostty 为默认Terminal
    run ${pkgs.duti}/bin/duti -s com.mitchellh.ghostty public.unix-executable all
  '';
}
