{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        type = "none"; # 禁用 logo
      };

      display = {
        separator = "  ->  ";

        color = {
          keys = "magenta"; # 全局键颜色
          output = "cyan"; # 全局输出颜色
        };
        key = {
          width = 10; # 确保对齐
          type = "icon"; # 保留图标样式（需确认版本支持）
        };
        size = {
          binaryPrefix = "jedec"; # MiB/GiB -> MB/GB
        };
      };

      modules = [
        "break"
        # 系统信息组（原 keyColor = "31"，改为 red）
        {
          type = "title";
          key = "User";
          keyColor = "red";
        }
        {
          type = "os";
          key = "OS";
          keyColor = "red";
          format = "{name} {version}";
        }
        {
          type = "kernel";
          key = "Kernel";
          keyColor = "red";
        }
        {
          type = "packages";
          key = "Packages";
          keyColor = "red";
        }
        {
          type = "shell";
          key = "Shell";
          keyColor = "red";
        }
        {
          type = "init";
          key = "Init System";
          keyColor = "red";
        }
        {
          type = "processes";
          key = "Processes";
          keyColor = "red";
        }
        {
          type = "users";
          key = "Users";
          keyColor = "red";
        }
        "break"
        # 桌面环境组（原 keyColor = "32"，改为 green）
        {
          type = "de";
          key = "Desktop";
          keyColor = "green";
        }
        {
          type = "wm";
          key = "WM";
          keyColor = "green";
        }
        {
          type = "wmtheme";
          key = "WM Theme";
          keyColor = "green";
        }
        {
          type = "theme";
          key = "System Theme";
          keyColor = "green";
        }
        {
          type = "icons";
          key = "Icons";
          keyColor = "green";
        }
        {
          type = "font";
          key = "Font";
          keyColor = "green";
        }
        {
          type = "cursor";
          key = "Cursor";
          keyColor = "green";
        }
        {
          type = "terminal";
          key = "Terminal";
          keyColor = "green";
        }
        {
          type = "terminalfont";
          key = "Terminal Font";
          keyColor = "green";
        }
        {
          type = "display";
          key = "Display";
          keyColor = "green";
        }
        "break"
        # 硬件信息组（原 keyColor = "33"，改为 yellow）
        {
          type = "host";
          format = "{5} {1} Type {2}";
          key = "Host";
          keyColor = "yellow";
        }
        {
          type = "board";
          key = "Motherboard";
          keyColor = "yellow";
        }
        {
          type = "chassis";
          key = "Chassis";
          keyColor = "yellow";
        }
        {
          type = "bios";
          key = "BIOS";
          keyColor = "yellow";
        }
        {
          type = "cpu";
          format = "{1} ({3}) @ {7} GHz";
          key = "CPU";
          keyColor = "yellow";
        }
        {
          type = "cpuusage";
          key = "CPU Usage";
          keyColor = "yellow";
          percent = {
            type = 3; # 百分比和进度条
            green = 30;
            yellow = 70;
          };
        }
        {
          type = "gpu";
          format = "{1} {2} @ {12} GHz";
          key = "GPU";
          keyColor = "yellow";
        }
        {
          type = "memory";
          key = "Memory";
          keyColor = "yellow";
          percent = {
            type = 3;
            green = 30;
            yellow = 70;
          };
        }
        {
          type = "swap";
          key = "Swap";
          keyColor = "yellow";
          percent = {
            type = 3;
            green = 30;
            yellow = 70;
          };
        }
        {
          type = "disk";
          key = "Disk";
          keyColor = "yellow";
          percent = {
            type = 3;
            green = 30;
            yellow = 70;
          };
        }
        {
          type = "monitor";
          key = "Monitor";
          keyColor = "yellow";
        }
        {
          type = "sound";
          key = "Sound";
          keyColor = "yellow";
        }
        {
          type = "gamepad";
          key = "Gamepad";
          keyColor = "yellow";
        }
        {
          type = "player";
          key = "Player";
          keyColor = "yellow";
        }
        {
          type = "media";
          key = "Media";
          keyColor = "yellow";
        }
        "break"
        # 网络与状态组（原 keyColor = "34"，改为 blue）
        {
          type = "datetime";
          key = "Date & Time";
          keyColor = "blue";
          format = "{1}-{3}-{11} {12} {14}:{17}:{20}";
          formatLocale = "zh_CN.UTF-8";
        }
        {
          type = "wifi";
          key = "WiFi";
          keyColor = "blue";
        }
        {
          type = "localip";
          key = "Local IP";
          keyColor = "blue";
        }
        {
          type = "publicip";
          key = "Public IP";
          keyColor = "blue";
        }
        {
          type = "bluetooth";
          key = "Bluetooth";
          keyColor = "blue";
        }
        {
          type = "netio";
          key = "Network IO";
          keyColor = "blue";
        }
        {
          type = "diskio";
          key = "Disk IO";
          keyColor = "blue";
        }
        {
          type = "battery";
          key = "Battery";
          keyColor = "blue";
          percent = {
            type = 3;
            green = 30;
            yellow = 70;
          };
        }
        {
          type = "poweradapter";
          key = "Power Adapter";
          keyColor = "blue";
        }
        {
          type = "brightness";
          key = "Brightness";
          keyColor = "blue";
        }
        {
          type = "temperature";
          key = "CPU Temp";
          keyColor = "blue";
        }
        {
          type = "loadavg";
          key = "Load Average";
          keyColor = "blue";
        }
        {
          type = "locale";
          key = "Locale";
          keyColor = "blue";
        }
        {
          type = "uptime";
          key = "Uptime";
          keyColor = "blue";
        }
        "break"
        # 图形与自定义组（使用 cyan 区分）
        {
          type = "vulkan";
          key = "Vulkan";
          keyColor = "cyan";
        }
        {
          type = "opengl";
          key = "OpenGL";
          keyColor = "cyan";
        }
        {
          type = "opencl";
          key = "OpenCL";
          keyColor = "cyan";
        }
        #        {
        #          type = "colors";
        #          key = "Colors";
        #          keyColor = "cyan";
        #        }
        #        {
        #          type = "custom";
        #          key = "Custom";
        #          keyColor = "cyan";
        #          text = "echo 'Custom Info'";
        #        }
      ];
    };
  };
}
