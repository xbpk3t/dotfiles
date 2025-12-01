{pkgs, ...}: let
  # PLAN [2025-11-24] jetbrains 远程开发。我需要 本地用mac作为workstation，具体的容器、服务 之类的跑在局域网下的 nixos 机器上
  # https://mynixos.com/nixpkgs/package/jetbrains.gateway
  # https://mynixos.com/home-manager/options/programs.jetbrains-remote
  # 先把结论说前面：
  #
  #* **JetBrains Gateway = JetBrains 官方的“远程开发客户端”**，类似 VS Code Remote，只不过是 JetBrains 版。
  #* **GoLand 是支持远程开发的**，可以通过：
  #
  #  1. **JetBrains Gateway + “远程后端（Remote Backend）”**（现代方案）
  #  2. **SSH 远程开发 / Remote Development**（界面集成在 IDE 里）
  #* 你的场景（本地 mac，代码 & 服务跑在局域网 NixOS 上）**完全可以用 GoLand 实现**，只要 NixOS 上能跑 JetBrains 后端或有 SSH。
  #
  #下面我分几块讲：
  #
  #---
  #
  ### 1. JetBrains Gateway 是什么？
  #
  #简单理解：
  #
  #> 在远程机器上跑 JetBrains IDE 的“头”，在本地只跑一个瘦客户端（Gateway），界面渲染和交互在本地，但**索引、分析、编译等重活都在远程机器上**。
  #
  #对比 VS Code：
  #
  #* VS Code Remote：本地 VS Code + 远端 vscode-server
  #* JetBrains Gateway：本地 Gateway (或 IDE) + 远端 JetBrains IDE Backend
  #
  #特点：
  #
  #* 远端负责索引、代码提示、重构等重计算
  #* 本地界面仍然是完整的 JetBrains IDE 体验（GoLand 的 UI / 快捷键等）
  #* 可以通过 **SSH / JetBrains Space / Gateway 专用协议** 连接
  #
  #---
  #
  ### 2. GoLand 支持哪些“远程开发”模式？
  #
  #对你的问题“GoLand 是否支持类似 VS Code Remote 这种服务？”——支持，主要有两种常见方式：
  #
  #### 2.1 使用 JetBrains Gateway + GoLand Backend（推荐）
  #
  #流程大概是：
  #
  #1. NixOS 上安装 JetBrains Gateway 所需的 **后端组件**（本质是 GoLand 的 headless 后端 / IDE backend）。
  #2. 在 mac 上安装 **JetBrains Gateway 应用**（或者在 Toolbox 里安装 Remote Development 支持）。
  #3. 用 Gateway 通过 **SSH 连接到你的 NixOS**，选择要用的 IDE（GoLand）。
  #4. Gateway 会在远程机器上拉起 GoLand backend，打开你指定的项目。
  #5. 之后你看到的是完整的 GoLand 界面，但所有索引、构建、go test 都在 NixOS 上跑。
  #
  #### 2.2 直接在 GoLand 中使用 Remote Development (内嵌 Gateway)
  #
  #新版 GoLand 里也有 “Remote Development” 入口，界面其实跟 Gateway 一样：
  #
  #* 在 Welcome 界面有“**Remote Development**”按钮
  #* 选择 “**SSH**” 模式
  #* 填远程主机、用户名、端口
  #* 选择 GoLand（或自动检测）
  #* 选择项目路径
  #
  #效果跟用独立的 JetBrains Gateway 客户端差不多，只是入口不一样。
  #
  #---
  #
  ### 3. 结合你具体场景：mac + 局域网 NixOS 的完整方案
  #
  #你的需求：
  #
  #> 本地 mac 当 workstation，NixOS 跑容器、服务，GoLand 能不能远程开发？
  #
  #可以，典型架构如下：
  #
  #* **NixOS 机器**：
  #
  #  * 存放代码仓库（git clone 在这台机上）
  #  * 跑 Go 编译 / go test / docker-compose / k8s / nix 容器等
  #* **mac**：
  #
  #  * 安装 JetBrains Gateway 或 GoLand（带 Remote Development）
  #  * 仅作 UI + 键盘鼠标 + 少量缓存
  #
  #### 3.1 前提准备
  #
  #在 NixOS 上你需要：
  #
  #1. **SSH 可用**：
  #
  #   * NixOS 上 `sshd` 开启
  #   * LAN 内 mac 能 `ssh user@your-nixos-ip`
  #2. NixOS 上有基本工具：
  #
  #   * Go 环境（`go`, `gofmt` 等）
  #   * git、bash/zsh 等 Shell
  #   * 推荐装好 Docker / Podman / Nix 容器工具（你已经有的话更好）
  #     3.（可选）NixOS 无 GUI 也没问题，**JetBrains 后端是 headless 的**。
  #
  #在 mac 上你需要：
  #
  #1. 安装 **JetBrains Toolbox**（管理 GoLand 和 Gateway 很方便）
  #2. 从 Toolbox 里：
  #
  #   * 安装 **GoLand**
  #   * 安装或启用 **Remote Development / JetBrains Gateway** 功能
  #     （也可以直接安装独立的 JetBrains Gateway 应用）
  #
  #---
  #
  ### 4. 实战步骤（按“SSH + Gateway”方式）
  #
  #下面按一步步操作来写，你可以照着做：
  #
  #### Step 1：确认 SSH 通
  #
  #在 mac 上：
  #
  #```bash
  #ssh youruser@your-nixos-ip
  #```
  #
  #能登录就 OK。若用非 22 端口记得记下端口号。
  #
  #### Step 2：在 mac 上打开 JetBrains Gateway
  #
  #方式一：单独的 Gateway 应用
  #方式二：打开 GoLand 的欢迎界面，点 **Remote Development**
  #
  #以 Gateway 为例：
  #
  #1. 打开 **JetBrains Gateway**
  #2. 选择 **SSH** 作为连接方式
  #3. 填写：
  #
  #   * Host: `your-nixos-ip`
  #   * Port: 22（或者你的自定义端口）
  #   * User: `youruser`
  #4. 点击 **Check Connection and Continue**
  #
  #若第一次连接，它会：
  #
  #* 询问是否添加 host key
  #* 验证密码 / ssh key
  #
  #### Step 3：选择 IDE 和部署后端
  #
  #连接成功后，Gateway 会让你：
  #
  #1. 选择要安装的 IDE backend
  #
  #   * 选 **GoLand**
  #   * 如果远端没装过，会提示在远端自动下载 & 安装 GoLand backend 到类似 `~/.cache/JetBrains/RemoteDev/` 目录
  #2. 选择远端项目目录：
  #
  #   * 比如 `/home/youruser/projects/my-go-service`
  #3. 点“Connect”，等待远端下载 + 启动后端
  #
  #> 这个阶段相当于 VS Code Remote 首次连上时装 `vscode-server`，但这里装的是 GoLand 的后端。
  #
  #### Step 4：使用体验
  #
  #连接成功后，你在 mac 上就看到一份 **完整的 GoLand 界面**：
  #
  #* 左边 Project 视图里展示的是 **远程 NixOS 上的文件树**
  #* 编辑器打开文件，保存时直接写到远端磁盘
  #* 代码提示、跳转、重构等都由远端 backend 完成
  #* 运行配置（Run/Debug Configurations）里的命令都在 NixOS 上跑：
  #
  #  * `go test ./...`
  #  * `go run ./cmd/server`
  #  * 调试：Go debugger 也跑在远端，Gateway 只是把 UI 显示出来
  #
  #### Step 5：和容器、服务联动
  #
  #你说“容器、服务跑在 NixOS”，非常适合远程开发：
  #
  #* GoLand 的 **Run/Debug configuration** 里直接配置命令：
  #
  #  * Docker Compose：如果你用 docker-compose，GoLand 可以调用远端 docker-compose
  #  * k8s/nix-shell 等：本质就是执行远端命令，可以通过 Shell script / Makefile 包起来
  #* 服务器启动后，端口是开在 NixOS 那台机上的，比如 `localhost:8080`（远端的 localhost）
  #
  #如果你想在 mac 浏览器访问：
  #
  #* 可以通过 **SSH 端口转发**：
  #
  #  * 启动开发会话前，在 mac 上：
  #
  #    ```bash
  #    ssh -L 8080:localhost:8080 youruser@your-nixos-ip
  #    ```
  #
  #  * 然后 mac 浏览器访问 `http://localhost:8080`，其实就是访问远端服务。
  #
  #> JetBrains Gateway 自身也有端口转发管理，你也可以在 UI 里配置，而不是自己敲 ssh 命令。
  #
  #---
  #
  ### 5. 和 VS Code Remote 对比，心里有个预期
  #
  #**相似点：**
  #
  #* 都是“本地 UI + 远端计算”的模式。
  #* 文件、工具链、服务都在远端，适合你这种“肥服务器 + 轻客户端”的架构。
  #
  #**不同点：**
  #
  #* VS Code remote 在远端跑的是 `vscode-server`；JetBrains 用的是各 IDE 的专用 backend。
  #* JetBrains 在索引 / 代码分析方面传统上更重，但**交互体验更接近本地 IDE**。
  #* 配置上 JetBrains Gateway 稍微“重量级”一些，但一旦连上，体验很统一。
  #
  #---
  #
  ### 6. NixOS 相关的小坑/注意事项
  #
  #因为你用的是 NixOS，有几点经验型提示（不一定都遇得到，但提前知道不亏）：
  #
  #1. **依赖路径**
  #   JetBrains 后端是它自己打包的 JBR（JetBrains Runtime，基于 JDK），大多数情况下不用你操心系统依赖。但你自己的 Go / docker / shell 等必须在 PATH 里：
  #
  #   * 在 NixOS 上，可以给 remote 用户配置一个合理的 shell（比如 `bashInteractive`）
  #   * 确保 `go`, `docker`, `git` 等在 `PATH` 里，`ssh` 登录后能直接运行。
  #
  #2. **无 GUI 没问题**
  #   JetBrains Backend 是 headless，不需要 X11/Wayland，也不需要桌面环境。
  #
  #3. **性能 / 磁盘空间**
  #   第一次连接会在 NixOS 上下载一个 GoLand 后端（几百 MB），注意给它预留一点磁盘空间。
  #
  #4. **固定版本**
  #   如果你用 Nix 管理 GoLand backend，也可以自己打包固定版本，但大多数人直接让 Gateway 自动安装即可。
  #
  #---
  #
  ### 7. 如果你不想用 Gateway，还有没有“简陋方案”？
  #
  #有，虽然不如 Gateway 舒服，但也可用：
  #
  #1. **直接在 NixOS 上跑完整 GoLand + X forwarding / VNC**
  #
  #   * 不推荐：体验一般、延迟大，而且浪费 mac 的图形能力。
  #
  #2. **代码放在 mac，本地 GoLand，通过 SSH / rsync / git 同步到 NixOS**
  #
  #   * 架构复杂度高，而且失去远端索引的优势，跟你现在要的方向不一样。
  #
  #就你的诉求来看，**Gateway / Remote Development 才是“现代正确姿势”**。
  #
  #---
  #
  ### 8. 小结（直接回答你的问题）
  #
  #> JetBrains Gateway 是啥？
  #
  #👉 JetBrains 的**远程开发客户端**，让 IDE 后端跑在远程机器上，本地只负责界面和交互。
  #
  #> GoLand 是否支持类似 VS Code Remote 这种服务？具体怎么用？
  #
  #👉 支持，通过 **JetBrains Gateway / Remote Development + SSH**：
  #
  #1. NixOS 开启 SSH，装好 Go / Docker 等开发环境；
  #2. mac 上安装 JetBrains Gateway / GoLand；
  #3. 在 Gateway 中配置 SSH 到 NixOS；
  #4. 选 GoLand 作为 IDE，选远端项目目录；
  #5. 连接后本地看到 GoLand 界面，所有操作（构建、调试、容器）都在 NixOS 上执行；
  #6. 如有需要，用端口转发在 mac 浏览器里访问远端服务。
  #
  #> 用 GoLand 能实现这套操作吗？
  #
  #👉 **可以，完全可以，而且是它的主打用例之一**。
  #
  #---
  #
  #如果你愿意，你可以给我：
  #
  #* NixOS 上项目的大致结构（单仓库、多服务、docker-compose、nix flake 等）
  #* 以及你现在用的运行方式（比如 `docker compose up`, `nix develop`, `go run ./cmd/api`）
  #
  #我可以直接帮你“设计一份 GoLand + Gateway 的具体配置方案”，包括 Run Config 写法、调试配置和端口转发建议。
  # Wrap GoLand so it always launches through XWayland. JetBrains still
  # lacks proper IME support on native Wayland, so we strip the Wayland
  # variables before delegating to the upstream launcher.
  goland-x11 = pkgs.symlinkJoin {
    name = "goland-x11";
    paths = [pkgs.jetbrains.goland];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/goland \
        --set GDK_BACKEND x11 \
        --set QT_QPA_PLATFORM xcb \
        --set SDL_VIDEODRIVER x11 \
        --set XDG_SESSION_TYPE x11 \
        --set NIXOS_OZONE_WL 0 \
        --unset WAYLAND_DISPLAY \
        --unset MOZ_ENABLE_WAYLAND \
        --unset ELECTRON_OZONE_PLATFORM_HINT
    '';
  };
in {
  home.packages = [goland-x11];

  # https://mynixos.com/home-manager/options/programs.vscode
  # https://mynixos.com/nixpkgs/packages/vscode-extensions
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # 保证 settings, ext, keybinds 相应配置文件可写
    mutableExtensionsDir = true;
    # mutableSettings = true;
    # mutableKeybindings = true;

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      extensions = with pkgs.vscode-extensions; [
        tuttieee.emacs-mcx

        # https://mynixos.com/nixpkgs/package/vscode-extensions.ziglang.vscode-zig
        # https://mynixos.com/nixpkgs/package/vscode-extensions.tiehuis.zig
        # used to replace tiehuis.zig
        ziglang.vscode-zig

        rust-lang.rust-analyzer
        kahole.magit
        graphql.vscode-graphql
        catppuccin.catppuccin-vsc
        bbenoist.nix
        jnoortheen.nix-ide
        golang.go
        ms-python.python
        redhat.vscode-yaml
        ms-azuretools.vscode-docker
        ms-vscode.cpptools
        hashicorp.terraform
        tamasfe.even-better-toml
        timonwong.shellcheck
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        streetsidesoftware.code-spell-checker
        eamodio.gitlens
        # vscodevim.vim

        ms-vscode.makefile-tools
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-containers
        github.vscode-pull-request-github
        ibm.output-colorizer
        oderwat.indent-rainbow
        formulahendry.code-runner
        gruntfuggly.todo-tree
      ];

      userSettings = {
        "breadcrumbs.enabled" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.bracketPairColorization.enabled" = true;
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "explicit";
          "source.organizeImports" = "explicit";
        };
        "editor.cursorSmoothCaretAnimation" = "on";
        #      "editor.fontFamily" = "Sarasa Mono SC";
        "editor.fontLigatures" = true;
        #      "editor.fontSize" = 13;
        "editor.formatOnPaste" = true;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.inlineSuggest.enabled" = true;
        "editor.linkedEditing" = true;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [80 100 120];
        "editor.smoothScrolling" = true;
        "editor.stickyScroll.enabled" = true;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "bounded";
        "editor.wordWrapColumn" = 120;

        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;

        "files.eol" = "\n";
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "files.watcherExclude" = {
          "**/.direnv/**" = true;
          "**/.jj/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
        };

        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        "gopls" = {
          "staticcheck" = true;
          "usePlaceholders" = true;
        };

        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "nixfmt";
        "nix.serverPath" = "nixd";

        "python.analysis.autoImportCompletions" = true;
        "python.formatting.provider" = "black";

        "remote.SSH.useLocalServer" = false;

        "rust-analyzer.cargo.buildScripts.enable" = true;
        "rust-analyzer.check.command" = "clippy";

        "search.exclude" = {
          "**/.direnv/**" = true;
          "**/.git/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
        };

        "security.workspace.trust.untrustedFiles" = "open";

        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.drawBoldTextInBrightColors" = false;
        #      "terminal.integrated.fontFamily" = "Sarasa Mono SC";
        #      "terminal.integrated.fontSize" = 12;

        "todo-tree.general.tags" = ["TODO" "FIXME" "BUG" "NOTE"];
        "todo-tree.tree.showScanModeButton" = false;

        "update.mode" = "none";
        "window.autoDetectColorScheme" = false;
        "window.commandCenter" = false;
        "window.titleBarStyle" = "custom";
        #      "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.editor.enablePreview" = false;
        "workbench.preferredDarkColorTheme" = "Catppuccin Mocha";
        "workbench.startupEditor" = "none";

        "[go]" = {
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit";
          };
          "editor.defaultFormatter" = "golang.go";
          "editor.formatOnSaveMode" = "file";
        };
        "[graphql]" = {
          "editor.defaultFormatter" = "graphql.vscode-graphql";
        };
        "[json]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[markdown]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.wordWrap" = "on";
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "[python]" = {
          "editor.defaultFormatter" = "ms-python.python";
        };
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        };
        "[toml]" = {
          "editor.defaultFormatter" = "tamasfe.even-better-toml";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[yaml]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };
      };
    };
  };
}
