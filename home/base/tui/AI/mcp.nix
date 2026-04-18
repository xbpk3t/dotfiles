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

  config = lib.mkIf mcpEnabled {
    programs.mcp.enable = true;

    home.packages = with pkgs; [
      # https://mynixos.com/nixpkgs/package/gitea-mcp-server
      # gitea-mcp-server

      # https://mynixos.com/nixpkgs/package/mcp-k8s-go
      #
      # https://github.com/strowk/mcp-k8s-go
      # https://github.com/containers/kubernetes-mcp-server
      #
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
        filesystem = {
          enable = true;
          args = [config.home.homeDirectory];
        };

        # https://mynixos.com/nixpkgs/package/github-mcp-server
        git.enable = true;
        fetch.enable = true;
        time.enable = true;
        memory.enable = true;

        # https://mynixos.com/nixpkgs/package/mcp-nixos
        nixos.enable = true;

        context7.enable = true;
        sequential-thinking.enable = true;

        # https://mynixos.com/nixpkgs/package/playwright-mcp
        playwright = {
          enable = true;
          # Darwin 下默认会走 pkgs.google-chrome，触发 Nix 构建 GoogleChrome-*.dmg。
          # 这里显式复用系统（brew 安装）的 Chrome，可避免重复下载/构建。
          executable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
        };
        # https://mynixos.com/nixpkgs/package/terraform-mcp-server
        terraform.enable = true;
        textlint = {
          enable = true;
          # textlint 模块要求 configFile 或 settings 至少配置其一；先给最小可用配置。
          settings = {
            rules = {};
          };
        };

        # 先预留，按需启用。
        # serena.enable = true;
        # https://mynixos.com/nixpkgs/package/mcp-grafana
        # grafana.enable = true;
      };

      settings.servers = {
        # NOTE: 新增 server 的工具名可能因上游版本调整，若失效可用 `codex mcp get <server>` 校对。
        git = {
          tools = {
            git_status.approval_mode = "approve";
            git_log.approval_mode = "approve";
            git_show.approval_mode = "approve";
            git_diff.approval_mode = "approve";
            git_diff_staged.approval_mode = "approve";
            git_diff_unstaged.approval_mode = "approve";
            git_add.approval_mode = "prompt";
            git_reset.approval_mode = "prompt";
            git_commit.approval_mode = "prompt";
            git_checkout.approval_mode = "prompt";
            git_create_branch.approval_mode = "prompt";
          };
        };

        fetch = {
          tools = {
            fetch.approval_mode = "approve";
          };
        };

        time = {
          tools = {
            get_current_time.approval_mode = "approve";
            convert_time.approval_mode = "approve";
          };
        };

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

        "sequential-thinking" = {
          tools = {
            sequentialthinking.approval_mode = "approve";
          };
        };

        memory = {
          tools = {
            add_observations.approval_mode = "prompt";
            create_entities.approval_mode = "prompt";
            create_relations.approval_mode = "prompt";
            delete_entities.approval_mode = "prompt";
            delete_observations.approval_mode = "prompt";
            delete_relations.approval_mode = "prompt";
            open_nodes.approval_mode = "approve";
            read_graph.approval_mode = "approve";
            search_nodes.approval_mode = "approve";
          };
        };

        context7 = {
          tools = {
            "query-docs".approval_mode = "approve";
            "resolve-library-id".approval_mode = "approve";
          };
        };

        nixos = {
          startup_timeout_sec = 50;
          tools = {
            nix.approval_mode = "approve";
            nix_versions.approval_mode = "approve";
          };
        };

        octocode = {
          command = "pnpm";
          args = [
            "dlx"
            "octocode-mcp@latest"
          ];
          tools = {
            githubGetFileContent.approval_mode = "approve";
            githubSearchCode.approval_mode = "approve";
            githubSearchPullRequests.approval_mode = "approve";
            githubSearchRepositories.approval_mode = "approve";
            githubViewRepoStructure.approval_mode = "approve";
          };
        };

        ddg = {
          command = "pnpm";
          args = [
            "dlx"
            "duckduckgo-mcp-server"
          ];
          tools = {
            duckduckgo_search.approval_mode = "approve";
          };
        };

        "code-index" = {
          command = "uvx";
          args = ["code-index-mcp"];
          tools = {
            build_deep_index.approval_mode = "approve";
            check_temp_directory.approval_mode = "approve";
            clear_settings.approval_mode = "prompt";
            configure_file_watcher.approval_mode = "prompt";
            create_temp_directory.approval_mode = "approve";
            find_files.approval_mode = "approve";
            get_file_summary.approval_mode = "approve";
            get_file_watcher_status.approval_mode = "approve";
            get_settings_info.approval_mode = "approve";
            get_symbol_body.approval_mode = "approve";
            refresh_index.approval_mode = "approve";
            refresh_search_tools.approval_mode = "approve";
            search_code_advanced.approval_mode = "approve";
            set_project_path.approval_mode = "prompt";
          };
        };

        # Chrome 146+ 推荐使用 --autoConnect 附着当前浏览器实例。
        # 前置条件: chrome://inspect/#remote-debugging 已开启 Remote debugging。
        "chrome-devtools" = {
          command = "npx";
          args = [
            "-y"
            "chrome-devtools-mcp@latest"
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

        playwright = {
          tools = {
            browser_snapshot.approval_mode = "approve";
            browser_take_screenshot.approval_mode = "approve";
            browser_network_requests.approval_mode = "approve";
            browser_console_messages.approval_mode = "approve";
            browser_wait_for.approval_mode = "approve";
            browser_navigate.approval_mode = "prompt";
            browser_click.approval_mode = "prompt";
            browser_hover.approval_mode = "prompt";
            browser_type.approval_mode = "prompt";
            browser_press_key.approval_mode = "prompt";
            browser_select_option.approval_mode = "prompt";
            browser_fill_form.approval_mode = "prompt";
            browser_go_back.approval_mode = "prompt";
            browser_go_forward.approval_mode = "prompt";
            browser_close.approval_mode = "prompt";
          };
        };

        terraform = {
          tools = {
            terraform_validate.approval_mode = "approve";
            terraform_plan.approval_mode = "approve";
            terraform_output.approval_mode = "approve";
            terraform_state_list.approval_mode = "approve";
            terraform_state_show.approval_mode = "approve";
            terraform_fmt.approval_mode = "approve";
            terraform_providers.approval_mode = "approve";
            terraform_init.approval_mode = "prompt";
            terraform_apply.approval_mode = "prompt";
            terraform_destroy.approval_mode = "prompt";
          };
        };

        textlint = {
          tools = {
            lint.approval_mode = "approve";
          };
        };

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

        # mcp-remote 代理模式: 本地 stdio <-> 远端 MCP over HTTP。
        # 暂不显式配置 tools：先保持默认 prompt。
        # 原因是远端 tool 清单可能随服务端变化，后续可在 `codex mcp get deepwiki` 后再精确补全。
        deepwiki = {
          command = "npx";
          args = [
            "-y"
            "mcp-remote"
            "https://mcp.deepwiki.com/mcp"
          ];
        };

        # [2026-01-09] 只保留HTTP版本，移除了stdio的本地版本
        #  github = {
        #    type = "http";
        #    url = "https://api.githubcopilot.com/mcp/";
        #    bearer_token_env_var = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN";
        #  };
        # 注意: Authorization header 里是占位符，真实 token 由 shell alias 在运行时注入。
        # 不要把真实 PAT 写死到仓库配置中。
        # 暂不显式配置 tools：官方 GitHub MCP 可能包含写操作，先保持默认 prompt 更稳妥。
        # 如果后续确认只想放行只读工具，再根据 `codex mcp get github` 的实际清单精确声明。
        github = {
          command = "npx";
          args = [
            "-y"
            "mcp-remote"
            "https://api.githubcopilot.com/mcp/"
            "--transport"
            "http-only"
            "--header"
            "Authorization: Bearer YOUR_GITHUB_PAT"
          ];
        };

        # Agent Browser (类似 bbrowser 之类的 web-access-tools)
        # MAYBE: [2026-04-16] 找到更好用的 Agent Browser （尝试 GenericAgent）
        # https://linux.do/t/topic/1962519
        # https://github.com/lsdefine/GenericAgent
        # https://linux.do/t/topic/1979802

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
      };
    };

    home = {
      sessionVariables = {
        # For Context7 MCP
        CONTEXT7_API_KEY = "$(cat ${config.sops.secrets.API_CONTEXT7.path})";
      };
    };
  };
}
