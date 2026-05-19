{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/fdroidcl
    # https://github.com/Hoverth/fdroidcl
    fdroidcl

    # https://mynixos.com/nixpkgs/package/android-tools
    # https://github.com/nmeum/android-tools
    android-tools

    # MAYBE: [2026-04-20] android-cli
    # https://developer.android.com/tools/agents/android-cli?hl=zh-cn
    # https://x.com/AI_jacksaku/status/2045342051097604405

    # https://github.com/tadfisher/android-nixpkgs
    # 注意与 android-tools 不同，这个 android-nixpkgs 是对于所有 Android SDK 的nix包装。
    # 但是更推荐使用 https://mynixos.com/nixpkgs/packages/androidenv.androidPkgs 而非这个flake。都是同一套东西，但是官方这套的version更stable

    # https://mynixos.com/nixpkgs/package/scrcpy
    # https://github.com/Genymobile/scrcpy
    # 用命令行控制Android设备 scrcpy = screen copy. Scrcpy uses adb to communicate with the device, and adb can connect to a device over TCP/IP. The device must be connected on the same network as the computer. 基于ADB来连接设备。也有类似 FreeControl 这样基于scrcpy实现的带GUI的项目。

    # https://github.com/barry-ran/QtScrcpy
    # https://mynixos.com/nixpkgs/package/qtscrcpy
    # 支持通过 USB 或 WIFI 一键连接 Android 设备到电脑，实现屏幕显示和控制，无需 root 权限。并提供了丰富功能，包括实时屏幕显示、键鼠控制、屏幕录制、截图、批量操作、文件传输、剪贴板同步等。
    scrcpy
  ];
}
