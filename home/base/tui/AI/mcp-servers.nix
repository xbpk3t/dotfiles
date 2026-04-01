{config}: {
  # 本MCP配置，可以在codex和claude-code中复用

  # https://www.tinyfish.ai/ TinyFish MCP，这个我觉得挺好，它能让 Claude 直接上网浏览、抓取网页、做资料调研，还能返回结构化结果，不只是给一段静态回答。我最近会拿它来给自己的周刊找 AI 新闻，比如抓最近几小时 Hacker News 上比较热门的内容，再整理成一份干净的摘要列表，效率很高。
  # https://github.com/excalidraw/excalidraw-mcp Excalidraw MCP，这个更适合拿来想事情，尤其是流程图、系统结构这类内容，靠文字说不清的时候，画一下会快很多。

  # TODO: programs.mcp ???
  # https://mynixos.com/home-manager/option/programs.mcp.servers
  # https://github.com/zhongjis/nix-config/blob/935ac824ed0c27868b9ae4e75753c8ad94508dd0/modules/home-manager/features/mcp.nix#L15

  # MAYBE: [2026-03-04] 等别人发 neo4j-mcp 了。官方3个方案：binary install, docker, 自己打包nixpkg. 前两种我不选，第三种嫌麻烦。当然mac上可以直接brew安装，但是不通用所以我也不选。
  # https://github.com/neo4j/mcp
  # https://neo4j.com/docs/mcp/current/

  # https://x.com/sitinme/status/2038571689441890311
  # 1.web-access
  #
  #给 Claude Code 补完整上网能力，它可以直接接管你正在用的 Chrome，连登录态都能复用。你已经登录的小红书、GitHub、各种网站，AI 都能直接进去看。还可以开子 Agent 并行查资料，查多个网站时速度明显快很多。
  #
  #2.Lightpanda
  #
  #它是直接从零造了一个给机器用的浏览器。不是 Chromium 魔改，是 Zig 从头写的。
  #特点：更轻、更快、更适合 Agent。跑大规模网页抓取和自动化时，性能和内存占用都挺夸张，属于那种一看就知道是冲着 Agent 时代来的基础设施。
  #
  #3.OpenClaw Zero Token
  #
  #通过浏览器自动化去复用网页端能力，想办法绕开官方 API 付费体系，还做了一个兼容 OpenAI 的网关，能直接接很多第三方客户端。
  #一句话总结就是：一个项目，尽量把 ChatGPT、Claude、Gemini 这类工具都“白嫖式”串起来。不过这种玩法合规和安全风险都不小，看看思路可以，真上生产得谨慎小心。
  #
  #4.bb-browser
  #
  #通过扩展 + CLI + MCP，把真实浏览器直接变成 Agent 的操作入口。很多常用网站都已经做好适配，AI 想搜内容、看社区、翻新闻，基本开箱就能跑。
  #
  #
  #web-access → 直接接管你正在用的 Chrome 会话，复用登录态 → MCP 典型用法。
  #Lightpanda → 从零用 Zig 写的极轻量浏览器，专门为 Agent 大规模抓取优化 → 底层浏览器基础设施，属于 MCP 生态。
  #OpenClaw Zero Token → 浏览器自动化绕 API 付费 + OpenAI 兼容网关 → 同样是给 Agent 提供真实网页操作能力，MCP 范畴。
  #bb-browser → 明确写着“扩展 + CLI + MCP”，把真实浏览器变成 Agent 操作入口，很多网站已预适配 → 直接就是 MCP server。
  #
  #总结：这几个都是给 Agent 接真实互联网的 MCP 类开源工具，而不是轻量化的 skills。
  #想用的话，bb-browser 和 web-access 上手最快（直接接现有 Chrome）；Lightpanda 适合追求极致性能的大规模场景。

  # filesystem MCP: 授权范围是整个 Home 目录，AI tool 可读写此目录下文件。
  # 如需最小权限，建议改成项目目录而不是 config.home.homeDirectory。
  filesystem = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-filesystem"
      config.home.homeDirectory
    ];
    # 这个 server 覆盖整个 Home，读操作默认放行，写操作保持显式确认。
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
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sequential-thinking"
    ];
    tools = {
      sequentialthinking.approval_mode = "approve";
    };
  };
  memory = {
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-memory"
    ];
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
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "@upstash/context7-mcp"
    ];
    # 依据 Context7 当前 MCP 命名，均为只读文档检索。
    tools = {
      "query-docs".approval_mode = "approve";
      "resolve-library-id".approval_mode = "approve";
    };
  };

  # startup_timeout_sec: 某些 Python/uvx MCP 首次 cold start 较慢，需要放宽超时。
  "nixos-mcp" = {
    type = "stdio";
    command = "uvx";
    args = ["mcp-nixos"];
    startup_timeout_sec = 50;
    tools = {
      nix.approval_mode = "approve";
      nix_versions.approval_mode = "approve";
    };
  };

  octocode = {
    type = "stdio";
    command = "pnpm";
    args = [
      "dlx"
      "octocode-mcp@latest"
    ];
    startup_timeout_sec = 30;
    # octocode 只提供 GitHub 只读检索/读取能力，默认直接放行，避免每次工具调用都手动确认。
    tools = {
      githubGetFileContent.approval_mode = "approve";
      githubSearchCode.approval_mode = "approve";
      githubSearchPullRequests.approval_mode = "approve";
      githubSearchRepositories.approval_mode = "approve";
      githubViewRepoStructure.approval_mode = "approve";
    };
  };
  ddg = {
    type = "stdio";
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
    type = "stdio";
    command = "uvx";
    args = ["code-index-mcp"];
    startup_timeout_sec = 30;
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
    type = "stdio";
    command = "npx";
    args = [
      "-y"
      "chrome-devtools-mcp@latest"
      "--autoConnect"
      "--channel"
      "stable"
    ];
    # 只默认放行观察/采样类工具；任何会改页面状态、提交输入或执行任意脚本的操作都要求确认。
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

  # mcp-remote 代理模式: 本地 stdio <-> 远端 MCP over HTTP。
  # 暂不显式配置 tools：先保持默认 prompt。
  # 原因是远端 tool 清单可能随服务端变化，后续可在 `codex mcp get deepwiki` 后再精确补全。
  deepwiki = {
    type = "stdio";
    command = "npx";
    args = ["-y" "mcp-remote" "https://mcp.deepwiki.com/mcp"];
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
    type = "stdio";
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

  # stitch MCP
  # https://linux.do/t/topic/1832590
  # https://github.com/davideast/stitch-mcp
  # https://stitch.withgoogle.com/docs/mcp/setup
}
