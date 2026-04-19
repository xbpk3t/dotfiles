{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  mcpEnabled =
    config.modules.AI.codex.enable
    || config.modules.AI.claude.enable;
in {
  # [2026-04-03] https://mynixos.com/home-manager/options/programs.mcp 最终是生成 $HOME/mcp/mcp.json 这么一个 mcp.json，跟目前所有cli都不一致（比如说 codex 的MCP的目标path就在config.toml, cc是 ~/.claude.json, cursor则是 $HOME/.cursor/mcp.json），所以没意义
  # [2026-04-03] 把mcp server由 mcp-servers-nix 管理，优势在于可以让 codex/cc 等所有cli复用一份mcp配置。带来的问题是 msn只有 command, args, env, url, headers 等通用字段，不支持codex的 approve 操作。
  # [2026-04-18] https://github.com/natsukium/mcp-servers-nix/issues/420 其实 MSN 是支持 approve 操作的，所以修改相应配置
  # [2026-04-18] 移除掉部分目前已经被主流agent（codex, cc）已经内置功能覆盖掉的mcp. sequential-thinking, ddg, octocode (被github mcp 替代), git (git操作已被主流agent完美支持), textlint, time (功能太简单，没必要)， memory (我其实并没有用这个 graph记忆，所以移除掉)

  imports = [
    inputs.mcp-servers-nix.homeManagerModules.default
  ];

  # MAYBE: [2026-04-03](excalidraw-mcp)
  # https://github.com/excalidraw/excalidraw-mcp Excalidraw MCP，这个更适合拿来想事情，尤其是流程图、系统结构这类内容，靠文字说不清的时候，画一下会快很多。

  # MAYBE: [2026-03-04](neo4j-mcp) 等别人发 neo4j-mcp 了。官方3个方案：binary install, docker, 自己打包nixpkg. 前两种我不选，第三种嫌麻烦。当然mac上可以直接brew安装，但是不通用所以我也不选。
  # https://github.com/neo4j/mcp
  # https://neo4j.com/docs/mcp/current/

  # MAYBE: [2026-04-03](stitch MCP)
  # https://linux.do/t/topic/1832590
  # https://github.com/davideast/stitch-mcp
  # https://stitch.withgoogle.com/docs/mcp/setup
  # https://x.com/yangyi/status/2040272305277079728
  # https://github.com/VoltAgent/awesome-design-md

  # 面向 win 的逆向分析MCP
  # https://linux.do/t/topic/1918792
  # https://github.com/Last-emo-boy/rikune

  # https://developers.openai.com/codex/mcp
  config = lib.mkIf mcpEnabled {
    programs.mcp.enable = true;

    home.packages = with pkgs; [
      # https://mynixos.com/nixpkgs/package/gitea-mcp-server
      # gitea-mcp-server

      # https://mynixos.com/nixpkgs/package/mcp-k8s-go
      # https://github.com/strowk/mcp-k8s-go
      # https://github.com/containers/kubernetes-mcp-server
      # mcp-k8s-go

      # https://mynixos.com/nixpkgs/package/aks-mcp-server
      # Azure Kubernetes Service
      # aks-mcp-server

      # https://mynixos.com/nixpkgs/package/fluxcd-operator-mcp
      # fluxcd-operator-mcp
    ];

    mcp-servers = {
      programs = {
        # filesystem MCP: 授权范围是整个 Home 目录，AI tool 可读写此目录下文件。
        # 如需最小权限，建议改成项目目录而不是 config.home.homeDirectory。
        # [2026-04-18] codex/cc 本身都可以通过 --add-dir 实现类似功能。但是其实我真正不想要的就是这个 --add-dir，会很麻烦，谁都跑到一半了，会因为没有某个folder的access权限，退出，然后重新resume+ add-dir进入？并且你说的也不对，设置home是有必要的，因为很多时候要搜索和操作的文件，也并不总是在上面这些path，我不可能为了以防万一加一堆path在这，懂吗？所以保留 filesystem，我需要保留这个全局默认可用的 $home 访问能力。
        filesystem = {
          enable = true;
          args = [config.home.homeDirectory];
        };

        fetch.enable = true;

        # https://mynixos.com/nixpkgs/package/mcp-nixos
        nixos.enable = true;

        # https://mynixos.com/nixpkgs/package/github-mcp-server
        github = {
          enable = true;
          passwordCommand = {
            GITHUB_PERSONAL_ACCESS_TOKEN = ["gh" "auth" "token"];
          };
        };

        context7 = {
          enable = true;
          passwordCommand = {
            CONTEXT7_API_KEY = ["cat" config.sops.secrets.API_CONTEXT7.path];
          };
        };

        # 先预留，按需启用。
        # serena.enable = true;
        # https://mynixos.com/nixpkgs/package/mcp-grafana
        # grafana.enable = true;

        # https://mynixos.com/nixpkgs/package/terraform-mcp-server
        # terraform.enable = true;

        # [2026-04-18] 用 chrome-devtools 替代掉了。playwright 更偏稳定自动化/脚本化操作，chrome-devtools 更偏调试、网络、console、性能、lighthouse、CDP 级观察。所以这组不是“完全同质”，但在日常使用中会明显抢同一个入口。
        # https://mynixos.com/nixpkgs/package/playwright-mcp
        #  playwright = {
        #    enable = true;
        #    # Darwin 下默认会走 pkgs.google-chrome，触发 Nix 构建 GoogleChrome-*.dmg。
        #    # 这里显式复用系统（brew 安装）的 Chrome，可避免重复下载/构建。
        #    executable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
        #  };
      };

      settings.servers = {
        # fetch 负责抓取页面内容
        # ddg 负责搜索
        # 严格说它们是上下游，不是同一个工具位；但从用户口径“帮我上网查资料”来看，它们经常服务同一个目标。也就是说，这组是工作流重叠，不是实现重叠。如果你偏向极简配置，这组也值得审视；但如果你希望“先搜索再打开”，保留两者是合理的。
        fetch = {
          tools = {
            fetch.approval_mode = "approve";
          };
        };

        # filesystem 可以列目录、读文件、搜索文件、读多文件、拿文件信息，甚至写改文件。filesystem 是通用文件系统能力。
        filesystem = {
          tools = {
            create_directory.approval_mode = "prompt";
            directory_tree.approval_mode = "approve";
            edit_file.approval_mode = "prompt";
            get_file_info.approval_mode = "approve";
            list_directory.approval_mode = "approve";
            list_directory_with_sizes.approval_mode = "approve";
            move_file.approval_mode = "prompt";
            read_file.approval_mode = "approve";
            read_media_file.approval_mode = "approve";
            read_multiple_files.approval_mode = "approve";
            read_text_file.approval_mode = "approve";
            search_files.approval_mode = "approve";
            write_file.approval_mode = "prompt";
          };
        };

        # https://github.com/johnhuang316/code-index-mcp
        # code-index 可以找文件、建索引、搜代码、拿 symbol body、文件摘要。code-index 是面向代码语义和索引的增强层。
        # [2026-04-19] 好像没什么人用，所以注释掉，之后再判断是否要移除掉
        #  "code-index" = {
        #    command = "uvx";
        #    args = ["code-index-mcp"];
        #    tools = {
        #      build_deep_index.approval_mode = "approve";
        #      check_temp_directory.approval_mode = "approve";
        #      clear_settings.approval_mode = "prompt";
        #      configure_file_watcher.approval_mode = "prompt";
        #      create_temp_directory.approval_mode = "approve";
        #      find_files.approval_mode = "approve";
        #      get_file_summary.approval_mode = "approve";
        #      get_file_watcher_status.approval_mode = "approve";
        #      get_settings_info.approval_mode = "approve";
        #      get_symbol_body.approval_mode = "approve";
        #      refresh_index.approval_mode = "approve";
        #      refresh_search_tools.approval_mode = "approve";
        #      search_code_advanced.approval_mode = "approve";
        #      set_project_path.approval_mode = "prompt";
        #    };
        #  };

        nixos = {
          startup_timeout_sec = 50;
          tools = {
            nix.approval_mode = "approve";
            nix_versions.approval_mode = "approve";
          };
        };

        # https://github.com/ChromeDevTools/chrome-devtools-mcp
        # Chrome 146+ 推荐使用 --autoConnect 附着当前浏览器实例。
        # 这里改为调用仓库内自打包的 `pkgs.chrome-devtools-mcp`，而不是 `npx ...@latest`。
        # Why:
        # - 这个仓库已经有自维护 `pkgs/` 入口，适合把常用 MCP server 纳入 declarative 管理；
        # - upstream npm tarball 已经带预编译产物，直接打包发布物比每次运行时走 npx 下载更稳，也更符合当前仓库的打包选型；
        # - 版本升级统一交给 nvfetcher，避免 MCP 启动时再发生隐式在线更新。
        # 前置条件: chrome://inspect/#remote-debugging 已开启 Remote debugging。
        "chrome-devtools" = {
          command = "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp";
          args = [
            "--autoConnect"
            "--channel"
            "stable"
          ];
          tools = {
            click.approval_mode = "prompt";
            close_page.approval_mode = "prompt";
            drag.approval_mode = "prompt";
            emulate.approval_mode = "prompt";
            evaluate_script.approval_mode = "prompt";
            fill.approval_mode = "prompt";
            fill_form.approval_mode = "prompt";
            get_console_message.approval_mode = "approve";
            get_network_request.approval_mode = "approve";
            handle_dialog.approval_mode = "prompt";
            hover.approval_mode = "prompt";
            lighthouse_audit.approval_mode = "approve";
            list_console_messages.approval_mode = "approve";
            list_network_requests.approval_mode = "approve";
            list_pages.approval_mode = "approve";
            navigate_page.approval_mode = "prompt";
            new_page.approval_mode = "prompt";
            performance_analyze_insight.approval_mode = "approve";
            performance_start_trace.approval_mode = "prompt";
            performance_stop_trace.approval_mode = "prompt";
            press_key.approval_mode = "prompt";
            resize_page.approval_mode = "prompt";
            select_page.approval_mode = "prompt";
            take_memory_snapshot.approval_mode = "prompt";
            take_screenshot.approval_mode = "approve";
            take_snapshot.approval_mode = "approve";
            type_text.approval_mode = "prompt";
            upload_file.approval_mode = "prompt";
            wait_for.approval_mode = "approve";
          };
        };

        # context7 偏库/框架文档
        context7 = {
          tools = {
            "query-docs".approval_mode = "approve";
            "resolve-library-id".approval_mode = "approve";
          };
        };

        # https://docs.devin.ai/work-with-devin/deepwiki-mcp
        # deepwiki 偏repo/wiki/远程 MCP 知识访问
        # mcp-remote 代理模式: 本地 stdio <-> 远端 MCP over HTTP。
        # 暂不显式配置 tools：先保持默认 prompt。
        # 原因是远端 tool 清单可能随服务端变化，后续可在 `codex mcp get deepwiki` 后再精确补全。
        # MAYBE: [2026-04-19] 因为是remote mcp，在init时很耗时，所以注释掉
        #  deepwiki = {
        #    command = "npx";
        #    args = [
        #      "-y"
        #      "mcp-remote"
        #      "https://mcp.deepwiki.com/mcp"
        #    ];
        #  };

        # https://github.com/epiral/bb-browser
        # bb-browser: 复用真实 Chrome 登录态的浏览器 MCP。
        # 这次选择它，不是因为它比 skill“更酷”，而是因为浏览器能力更适合作为 MCP 能力层接入。
        # upstream README 直接给出了 MCP 用法：`npx -y bb-browser --mcp`。
        # 与 chrome-devtools 的边界：
        # - chrome-devtools 偏通用 CDP / DevTools 调试与页面观察
        # - bb-browser 偏“真实浏览器 + 登录态 + 站点适配 + AI 直接取数/操作”
        # 暂不显式配置 tools：先保持默认 prompt。
        # 原因是 bb-browser 的 tool 清单需要在实际接入后通过 `codex mcp get bb-browser` 再精确补全。
        #  "bb-browser" = {
        #    command = "npx";
        #    args = [
        #      "-y"
        #      "bb-browser"
        #      "--mcp"
        #    ];
        #  };

        #  terraform = {
        #    tools = {
        #      terraform_validate.approval_mode = "approve";
        #      terraform_plan.approval_mode = "approve";
        #      terraform_output.approval_mode = "approve";
        #      terraform_state_list.approval_mode = "approve";
        #      terraform_state_show.approval_mode = "approve";
        #      terraform_fmt.approval_mode = "approve";
        #      terraform_providers.approval_mode = "approve";
        #      terraform_init.approval_mode = "prompt";
        #      terraform_apply.approval_mode = "prompt";
        #      terraform_destroy.approval_mode = "prompt";
        #    };
        #  };

        #  playwright = {
        #    tools = {
        #      browser_snapshot.approval_mode = "approve";
        #      browser_take_screenshot.approval_mode = "approve";
        #      browser_network_requests.approval_mode = "approve";
        #      browser_console_messages.approval_mode = "approve";
        #      browser_wait_for.approval_mode = "approve";
        #      browser_navigate.approval_mode = "prompt";
        #      browser_click.approval_mode = "prompt";
        #      browser_hover.approval_mode = "prompt";
        #      browser_type.approval_mode = "prompt";
        #      browser_press_key.approval_mode = "prompt";
        #      browser_select_option.approval_mode = "prompt";
        #      browser_fill_form.approval_mode = "prompt";
        #      browser_go_back.approval_mode = "prompt";
        #      browser_go_forward.approval_mode = "prompt";
        #      browser_close.approval_mode = "prompt";
        #    };
        #  };

        # 先预留，按需启用（当前先注释）。
        # serena = {
        #   tools = {
        #     find_symbol.approval_mode = "approve";
        #     find_referencing_symbols.approval_mode = "approve";
        #     get_symbols_overview.approval_mode = "approve";
        #     replace_symbol_body.approval_mode = "prompt";
        #   };
        # };
        # grafana = {
        #   tools = {
        #     search_dashboards.approval_mode = "approve";
        #     get_dashboard.approval_mode = "approve";
        #     query_datasource.approval_mode = "approve";
        #   };
        # };
      };
    };

    #    home = {
    #      sessionVariables = {
    #        # For Context7 MCP
    #        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_CONTEXT7.path})";
    #      };
    #    };
  };
}
