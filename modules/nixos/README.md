## modules/nixos/base

本模块只放“所有机器都应一致”的基线：语言/时区、logind、zram/oom、nix 工具链、通用用户/组等。


可以保留在 base 的

- i18n.nix、logind.nix、shell.nix（通用 shell/补全）、nix-tools.nix、user-
  group.nix、zram.nix（如所有机器都启用 swap/zram）。


- 注意 common 和 server/desktop 里面的配置需要完全正交。具体来说，某个配置项，如果在common里出现了，那么就不应该再出现在 server or desktop里。而 server 和 desktop 里的配置项是可以重复的。

所以在 openssh.nix, security.nix 等文件里，都做了 isServer/isDesktop 这样的

之所以




:::tip

把 Linux-Optimizer 里的linux优化都整合到nixos配置里。

:::




### tailscale/netbird

:::tip

作为 host=nixos-vps，所有VPS就既是 tailscale 的 client (=node) 和 Derp Relay Server

:::






## modules/nixos/desktop


:::tip

以GNOME作为desktop的核心来添加配置项

直接使用GNOME这种主流DE，对于 Linux Desktop 来说，就是最方便好用的选择

:::


### 2025-12-21

移除掉

modules/nixos/desktop 里的

因为 GNOME本身就支持该功能

- cliphist
- thunar
- swaybg
- swaylock, swayidle
- sunsetr
- flameshot


---


```nix title="home/nixos/desktop/default.nix"

  home.packages = with pkgs; [
    # reqable

    # Media
    # vlc

    # Image viewers
    # feh
    # imv

    wl-clipboard # copying and pasting
    brightnessctl
    wf-recorder # screen recording
    alsa-utils # provides amixer/alsamixer/...
    # networkmanagerapplet # provide GUI app: nm-connection-editor
  ];

```


```nix

{pkgs, ...}:
# media - control and enjoy audio/video
{
  home.packages = with pkgs; [
    # audio control
    pavucontrol # pulsemixer
    playerctl

    imv # simple image viewer

    # video/audio tools
    libva-utils
    vdpauinfo
    vulkan-tools

    mesa-demos # glxinfo

    nvitop
  ];

  services = {
    playerctld.enable = true;
  };
}


```


```markdown
这些包都只是“工具/前端”，与 PipeWire 音频栈配置无关，不建议直接塞进 modules/nixos/desktop/audio.nix（那是系统级音频服务模块）。如果只用 GNOME，逐个判断如下（2025‑12‑10）：

- pavucontrol：GNOME 设置里已有音量/路由控制；仅在你想要更细粒度路由时保留。
- playerctl/playerctld：GNOME 媒体键已经通过 MPRIS 控制常见播放器，不必需；除非你有脚本或快捷键依赖它。
- imv：GNOME 自带图像查看器（Loupe/eog），imv 只在 Wayland+平铺 WM 场景更轻量；纯 GNOME 可删。
- libva-utils, vdpauinfo, vulkan-tools, mesa-demos：全是 GPU/视频加速诊断工具，日常不需要；调试硬解或性能时再装。
- nvitop：仅在有 NVIDIA GPU 且需要监控时有用；否则删除。

结论：在只用 GNOME 的前提下，这个 home/nixos/desktop/media.nix 可以整体停用；若未来偶尔调试再临时安装即可。若要保留少量工具，放在 home/nixos/desktop/gnome.nix（或单独 tools.nix）的home.packages 更合适，不要混进系统级的 modules/nixos/desktop/audio.nix。


```

---

- 移除掉 gtk.nix, xdg.nix。同样在 GNOME下不再需要。
- 移除掉 neomutt, notmuch, mbsync 之类的 `accounts.email` 相关配置
- 移除掉 below, coredump

https://mynixos.com/nixpkgs/options/services.below

https://mynixos.com/nixpkgs/options/systemd.coredump



```markdown
- libnotify：GNOME 已自带通知守护进程；除非有命令行工具需要 notify-send，一般可以省略。
- wireguard-tools：如果你在宿主机手动管理 WG（wg-quick/wg），仍需；若都在容器或 NetworkManager 配置，宿主可
  不装。
- virt-viewer：只在需要 VNC/SPICE 远程查看 VM（如 kubevirt/virt-manager）时装；不用虚机即可去掉。
- udiskie 自动挂载：GNOME 自带 gvfs/gnome-shell 自动弹出与挂载，通常不需要 udiskie；如果你想在纯终端会话下
  自动挂载，可保留。

```









## modules/nixos/laptop




## modules/nixos/extra
