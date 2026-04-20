{pkgs, ...}: {
  # 为啥选择 lazyjournal？
  # 目前没有对标工具，systemctl-tui, lnav, journal-viewer, sysz 这些在 journaltcl 场景下都不如 lazyjournal

  #可以，按你这个 Taskfile 来映射的话：
  #
  #### `recent`
  #
  #最接近的操作：
  #
  #1. 启动 `lazyjournal`
  #2. `Tab` 切到 **journals** 区域
  #3. 用 `h` / `l` 在不同 journald 列表之间切换，切到 **System journals** 或 **System units**
  #4. 用 `j` / `k` 选中目标项
  #5. `Enter` 加载日志
  #6. `Ctrl+E` 跳到末尾，`Ctrl+A` 跳到开头，`/` 进入过滤。
  #
  #要注意一点：
  #你的 `recent` 是 `journalctl -n "$lines"`，本质上是**直接看“全局最近 N 条混合系统日志”**；而 LazyJournal 更偏向**先选日志源，再看这个源的日志**。它会展示 **System units / User units / System journals** 这类列表，再进去看具体项，所以它**不是 1:1 对应** `journalctl -n 100` 那种“所有日志混在一起 tail 一段”的视图。官方配置和调试输出里也能看到它的 journald 入口是这些列表，并且 `System journals` 是按 `journalField`（默认 `SYSLOG_IDENTIFIER`）组织的。
  #
  #还有一个差异：
  #LazyJournal 默认 tail 行数是 **10000**，可通过配置或 `-t/--tail-lines` 改，但 flag 说明里范围是 **200–200000**，所以它也**不能精确还原你默认的 100 行**。
  #
  #---
  #
  #### `service`
  #
  #这个是 **最贴合** 的。
  #
  #对应操作：
  #
  #1. 启动 `lazyjournal`
  #2. 默认 `SystemLogList` 就是 `systemUnits`
  #3. 在 **System units** 列表里用 `j` / `k` 找服务
  #4. `/` 可直接过滤服务名，比如输 `sshd`、`traefik`
  #5. `Enter` 打开该服务日志。
  #
  #这基本就是你这个：
  #
  #```bash
  #journalctl -u "{{.SVC}}" -n 100 --no-pager
  #```
  #
  #里的 `-u`，也就是按 **systemd unit/service** 看日志。LazyJournal README 明确写了它有 **“List of all services … with current state from systemd to access their logs”**。
  #
  #---
  #
  #### `follow`
  #
  #这个也很贴合。
  #
  #对应操作：
  #
  #1. 先像上面那样进到某个服务，或者某个 journald source
  #2. 进入日志后，默认就是**流式更新新事件**，相当于 `tail -f`
  #3. `Ctrl+S` 可以切换 stream mode
  #4. `Ctrl+U` 控制自动更新
  #5. `Ctrl+R` 手动刷新一次。
  #
  #因为 LazyJournal 默认 `tailModeDisable: false`，而且 help 里明确说 `--tail-mode-disable` 才是“关闭新事件流式更新”，所以默认行为就是持续跟新日志。
  #
  #---
  #
  #### 直接总结成映射
  #
  #* `recent` → **部分对应**：进 journald 列表后选 source 看最近日志，但不是 `journalctl -n` 那种“全局混合最近 N 条”
  #* `service` → **强对应**：`System units` 里搜服务，`Enter`
  #* `follow` → **强对应**：进入日志后默认就是流式跟随，`Ctrl+S / Ctrl+U / Ctrl+R` 辅助控制。

  # LazyJournal 能不能复制日志、导出日志？怎么操作？
  # 复制文本：支持
  #主要依赖终端选择复制，比如 Alt+Shift + 鼠标
  #直接导出当前视图到文件：我没有查到官方文档化支持
  #-l/--logging：
  #不是导出日志
  #而是把 LazyJournal 自己执行的命令写到日志文件中，便于调试/追踪
  #所以当时我给你的实战建议是：
  #
  #用 LazyJournal 找问题、筛选、定位
  #真正要导出时，还是回到 journalctl

  # sudo journalctl -u singbox -f
  # 这里的 -u 是啥意思？
  # 搭配
  # journalctl -u traefik --since "2026-01-10" --no-pager | tail -n 50

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/lazyjournal
    # https://github.com/Lifailon/lazyjournal
    lazyjournal

    # 更成熟的通用日志分析器，适合搭配 journalctl
    # https://github.com/tstack/lnav
    # https://mynixos.com/nixpkgs/package/lnav
  ];

  home.file.".config/lazyjournal/config.yml" = {
    source = ./lazyjournal.yml;
    force = true;
  };
}
