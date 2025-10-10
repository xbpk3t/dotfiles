{pkgs, ...}: {
  # FIXME 怎么在codex、cc 之间复用这些commands和agents?
  #  # 自动发现 cc 目录中的命令文件
  #  subagentsDir = ./cc/subagents;
  #  agents =
  #    lib.mapAttrs'
  #    (
  #      fileName: _:
  #        lib.nameValuePair
  #        (lib.removeSuffix ".md" fileName)
  #        (builtins.readFile (subagentsDir + "/${fileName}"))
  #    )
  #    (builtins.readDir subagentsDir);
  #
  #  commandsDir = ./cc/commands;
  #  commands =
  #    lib.mapAttrs'
  #    (
  #      fileName: _:
  #        lib.nameValuePair
  #        (lib.removeSuffix ".md" fileName)
  #        (builtins.readFile (commandsDir + "/${fileName}"))
  #    )
  #    (builtins.readDir commandsDir);

  # Claude CLI 环境变量配置
  home = {
    sessionVariables = {
      # 自定义 API 端点，用于连接到第三方模型服务
      ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
      # API 认证令牌 - 使用 sops 管理，通过 cat 命令读取文件内容
      ANTHROPIC_AUTH_TOKEN = builtins.readFile /etc/sk/claude/zai/token;
    };
    shellAliases = {
      cc = "claude --dangerously-skip-permissions";
    };
  };

  programs = {
    # Shell 配置 - 添加 Claude Code 相关的 shell 功能
    zsh.initContent = ''

    '';

    #    codex = {
    #      enable = true;
    #      package = pkgs.codex;
    #      #    settings = {
    #      #      approval_policy = "on-request";
    #      #      sandbox_mode = "workspace-write";
    #      #      file_opener = "cursor";
    #      #      tools = { web_search = true; };
    #      #      mcp_servers = {
    #      #        github = {
    #      #          command = "github-mcp-server";
    #      #          args = [ "stdio" ];
    #      #          env = { GITHUB_PERSONAL_ACCESS_TOKEN = githubMcpToken; };
    #      #        };
    #      #        rails = {
    #      #          command = "rails-mcp-server";
    #      #          args = [ "stdio" ];
    #      #          env = { };
    #      #        };
    #      #      };
    #      #    };
    #
    #      #    settings = {
    #      #        model = "gpt-5";
    #      #        model_provider = "openai";
    #      #        model_providers = {
    #      #          openai = {
    #      #            # Name of the provider that will be displayed in the Codex UI.
    #      #            name = "OpenAI using Chat Completions";
    #      #            base_url = "https://api.openai.com/v1";
    #      #            env_key = "OPENAI_API_KEY";
    #      #            wire_api = "chat";
    #      #            query_params = {};
    #      #          };
    #      #        };
    #      #    };
    #      # Custom guidance for the agent(s)
    #      custom-instructions = ''
    #      '';
    #    };

    # Claude Code 程序配置
    claude-code = {
      enable = true;
      package = pkgs.claude-code;

      mcpServers = {
        filesystem = {
          type = "stdio";
          command = "pnpm";
          args = ["dlx" "@modelcontextprotocol/server-filesystem"];
        };
        sequential-thinking = {
          type = "stdio";
          command = "pnpm";
          args = ["dlx" "@modelcontextprotocol/server-sequential-thinking"];
        };
        memory = {
          type = "stdio";
          command = "pnpm";
          args = ["dlx" "@modelcontextprotocol/server-memory"];
        };

        nixos-mcp = {
          type = "stdio";
          command = "uvx";
          args = ["mcp-nixos"];
        };

        octocode = {
          type = "stdio";
          command = "pnpm";
          args = ["dlx" "octocode-mcp@latest"];
        };

        ddg = {
          type = "stdio";
          command = "pnpm";
          args = ["dlx" "duckduckgo-mcp-server"];
        };

        deepwiki = {
          type = "http";
          url = "https://mcp.deepwiki.com/mcp";
        };

        context7 = {
          type = "http";
          url = "https://mcp.context7.com/mcp";
        };

        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
        };

        claude-task-master = {
          type = "stdio";
          command = "npx";
          args = ["-y" "task-master-ai"];
          env = {
            ANTHROPIC_API_KEY = builtins.readFile /etc/sk/claude/zai/token;
          };
        };

        # [johnhuang316/code-index-mcp](https://github.com/johnhuang316/code-index-mcp) 用于提高编写代码的效率和检索效率
        code-index = {
          type = "stdio";
          command = "uvx";
          args = ["code-index-mcp"];
        };

        # Microsoft Markitdown - Convert various file formats to Markdown (Useful for document processing)
        markitdown = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@microsoft/markitdown-mcp"];
        };

        # GitHub Official MCP Server (Essential for GitHub integration)
        github-mcp = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@github/github-mcp-server"];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = builtins.readFile /etc/sk/claude/github-token;
          };
        };

        # Microsoft Playwright - Automate web browsers (Useful for testing and web automation)
        playwright = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@microsoft/playwright-mcp"];
        };

        # Serena - Semantic code retrieval & editing (Useful for code analysis)
        serena = {
          type = "stdio";
          command = "npx";
          args = ["-y" "serena-mcp"];
        };

        # Firecrawl - Extract web data (Useful for web scraping and content extraction)
        firecrawl = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@firecrawl/firecrawl-mcp-server"];
          env = {
            FIRECRAWL_API_KEY = builtins.readFile /etc/sk/claude/firecrawl-token;
          };
        };

        jetbrains = {
          type = "sse";
          url = "http://localhost:64342/sse";
        };

        # Notion Official MCP Server (Useful if you use Notion)
        # notion = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@notionhq/notion-mcp-server"];
        #   env = {
        #     NOTION_TOKEN = "builtins.readFile /etc/claude/notion-token
        #   };
        # };

        # Unity - Control Unity Editor (Only if you work with Unity)
        # unity = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@coplaydev/unity-mcp"];
        # };

        # Azure services integration (Enterprise cloud services - rarely used for personal projects)
        # azure = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@azure/azure-mcp"];
        #   env = {
        #     AZURE_SUBSCRIPTION_ID = "builtins.readFile /etc/claude/azure-subscription-id
        #     AZURE_TENANT_ID = "builtins.readFile /etc/claude/azure-tenant-id
        #     AZURE_CLIENT_ID = "builtins.readFile /etc/claude/azure-client-id
        #     AZURE_CLIENT_SECRET = "builtins.readFile /etc/claude/azure-client-secret
        #   };
        # };

        # Stripe - Payment API integration (Only if you work with payments)
        # stripe = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@stripe/agent-toolkit"];
        #   env = {
        #     STRIPE_API_KEY = "builtins.readFile /etc/claude/stripe-api-key
        #   };
        # };

        # Terraform - Infrastructure as Code (Useful for DevOps)
        terraform = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@hashicorp/terraform-mcp-server"];
        };

        # Microsoft Learn - Official documentation (Useful for Microsoft tech docs)
        # microsoft-learn = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@microsoftdocs/mcp"];
        # };

        # Azure DevOps (Microsoft-specific DevOps - rarely used outside Microsoft ecosystem)
        # azure-devops = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@microsoft/azure-devops-mcp"];
        #   env = {
        #     AZURE_DEVOPS_TOKEN = "builtins.readFile /etc/claude/azure-devops-token
        #   };
        # };

        # Nuxt - Vite/Nuxt app understanding (Only if you use Nuxt.js)
        # nuxt = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@antfu/nuxt-mcp"];
        # };

        # MongoDB - Database integration (Only if you use MongoDB)
        # mongodb = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@mongodb/mongodb-mcp-server"];
        #   env = {
        #     MONGODB_URI = "builtins.readFile /etc/claude/mongodb-uri
        #   };
        # };

        # Elasticsearch - Search and analytics (Enterprise search - rarely used personally)
        # elasticsearch = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@elastic/mcp-server-elasticsearch"];
        #   env = {
        #     ELASTICSEARCH_URL = "builtins.readFile /etc/claude/elasticsearch-url
        #     ELASTICSEARCH_API_KEY = "builtins.readFile /etc/claude/elasticsearch-api-key
        #   };
        # };

        # Neon - PostgreSQL database platform (Only if you use Neon specifically)
        # neon = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@neondatabase/mcp-server-neon"];
        #   env = {
        #     NEON_API_KEY = "builtins.readFile /etc/claude/neon-api-key
        #   };
        # };

        # Chroma - Vector database (Only if you work with vector databases)
        # chroma = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@chroma-core/chroma-mcp"];
        #   env = {
        #     CHROMA_URL = "builtins.readFile /etc/claude/chroma-url
        #   };
        # };

        # Sentry - Error tracking (Only if you use Sentry for error monitoring)
        # sentry = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@getsentry/sentry-mcp"];
        #   env = {
        #     SENTRY_AUTH_TOKEN = "builtins.readFile /etc/claude/sentry-token
        #   };
        # };

        # Monday.com - Work management (Only if you use Monday.com)
        # monday = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@mondaycom/mcp"];
        #   env = {
        #     MONDAY_API_KEY = "builtins.readFile /etc/claude/monday-api-key
        #   };
        # };

        # Azure AI Foundry (Microsoft-specific AI platform)
        # azure-ai-foundry = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@azure-ai-foundry/mcp-foundry";
        #   env = {
        #     AZURE_AI_FOUNDRY_KEY = "builtins.readFile /etc/claude/azure-ai-foundry-key
        #   };
        # };

        # Imagesorcery - Local image processing (Useful for image manipulation)
        imagesorcery = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@sunriseapps/imagesorcery-mcp"];
        };

        # Dynatrace - Observability platform (Enterprise monitoring)
        # dynatrace = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@dynatrace-oss/dynatrace-mcp";
        #   env = {
        #     DYNATRACE_API_TOKEN = "builtins.readFile /etc/claude/dynatrace-api-token
        #     DYNATRACE_BASE_URL = "builtins.readFile /etc/claude/dynatrace-base-url
        #   };
        # };

        # Logfire - OpenTelemetry traces and metrics (Observability)
        # logfire = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@pydantic/logfire-mcp";
        #   env = {
        #     LOGFIRE_API_KEY = "builtins.readFile /etc/claude/logfire-api-key
        #   };
        # };

        # Azure Kubernetes Service (Microsoft container service)
        # aks = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@azure/aks-mcp";
        #   env = {
        #     AZURE_SUBSCRIPTION_ID = "builtins.readFile /etc/claude/azure-subscription-id
        #     AZURE_TENANT_ID = "builtins.readFile /etc/claude/azure-tenant-id
        #     AZURE_CLIENT_ID = "builtins.readFile /etc/claude/azure-client-id
        #     AZURE_CLIENT_SECRET = "builtins.readFile /etc/claude/azure-client-secret
        #   };
        # };

        # Hugging Face - Models and datasets (Very useful for AI/ML work)
        huggingface = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@evalstate/hf-mcp-server"];
          env = {
            HF_TOKEN = builtins.readFile /etc/sk/claude/huggingface-token;
          };
        };

        # Webflow - Web design platform (Only if you use Webflow)
        # webflow = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@webflow/mcp-server";
        #   env = {
        #     WEBFLOW_API_TOKEN = "builtins.readFile /etc/claude/webflow-token
        #   };
        # };

        # Fabric Real-Time Intelligence (Microsoft analytics platform)
        # fabric-rti = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@microsoft/fabric-rti-mcp";
        #   env = {
        #     FABRIC_API_KEY = "builtins.readFile /etc/claude/fabric-api-key
        #   };
        # };

        # Box - Enterprise content management (Enterprise file storage)
        # box = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@box-community/mcp-server-box";
        #   env = {
        #     BOX_DEVELOPER_TOKEN = "builtins.readFile /etc/claude/box-developer-token
        #   };
        # };

        # Codacy - Code quality and security (Code analysis platform)
        # codacy = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@codacy/codacy-mcp-server";
        #   env = {
        #     CODACY_API_TOKEN = "builtins.readFile /etc/claude/codacy-api-token
        #   };
        # };

        # Microsoft Clarity - Analytics (Web analytics)
        # clarity = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@microsoft/clarity-mcp-server";
        #   env = {
        #     CLARITY_API_KEY = "builtins.readFile /etc/claude/clarity-api-key
        #   };
        # };

        # Postman - API development (Useful for API testing and development)
        postman = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@postmanlabs/postman-mcp-server"];
          env = {
            POSTMAN_API_KEY = builtins.readFile /etc/sk/claude/postman-api-key;
          };
        };

        # LaunchDarkly - Feature flags (Feature flag management)
        # launchdarkly = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@launchdarkly/mcp-server";
        #   env = {
        #     LAUNCHDARKLY_API_KEY = "builtins.readFile /etc/claude/launchdarkly-api-key
        #   };
        # };

        # Atlassian - Jira and Confluence (Project management and documentation)
        # atlassian = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@atlassian/atlassian-mcp-server";
        #   env = {
        #     ATLASSIAN_API_TOKEN = "builtins.readFile /etc/claude/atlassian-api-token
        #   };
        # };

        # Figma Dev Mode - Design context (Very useful for design-development workflow)
        figma = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@figma/dev-mode-mcp-server"];
          env = {
            FIGMA_API_KEY = builtins.readFile /etc/sk/claude/figma-api-key;
          };
        };

        # JFrog - DevOps platform (Artifact management)
        # jfrog = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@jfrog/jfrog-mcp-server";
        #   env = {
        #     JFROG_URL = "builtins.readFile /etc/claude/jfrog-url
        #     JFROG_USERNAME = "builtins.readFile /etc/claude/jfrog-username
        #     JFROG_PASSWORD = "builtins.readFile /etc/claude/jfrog-password
        #   };
        # };

        # Microsoft Dev Box (Cloud development environment)
        # devbox = {
        #   type = "stdio";
        #   command = "npx";
        #   args = ["-y" "@microsoft/devbox-mcp-server";
        #   env = {
        #     AZURE_SUBSCRIPTION_ID = "builtins.readFile /etc/claude/azure-subscription-id
        #     AZURE_TENANT_ID = "builtins.readFile /etc/claude/azure-tenant-id
        #     AZURE_CLIENT_ID = "builtins.readFile /etc/claude/azure-client-id
        #     AZURE_CLIENT_SECRET = "builtins.readFile /etc/claude/azure-client-secret
        #   };
        # };

        # Zapier - Automation platform (Very useful for workflow automation)
        zapier = {
          type = "stdio";
          command = "npx";
          args = ["-y" "@zapier/zapier-mcp"];
          env = {
            ZAPIER_API_KEY = builtins.readFile /etc/sk/claude/zapier-api-key;
          };
        };
      };

      # 编辑器和行为设置
      settings = {
        theme = "dark";
        outputStyle = "Explanatory";
        includeCoAuthoredBy = false;
        cleanupPeriodDays = 7;

        editor = {
          lineNumbers = true;
          wordWrap = true;
          minimap = false;
          theme = "auto";
        };
        #  behavior = {
        #    autoSave = true;
        #    confirmOnExit = false;
        #    showLineNumbers = true;
        #  };

        permissions = {
          additionalDirectories = [
            "~/Desktop"
          ];
          allow = [
            # === Web & Network Operations ===
            "WebFetch(domain:docs.anthropic.com)"
            "WebFetch(domain:github.com)"
            "WebFetch(domain:api.github.com)"
            "WebFetch"
            "WebSearch"

            # === File System Operations ===
            "Bash(rm:*)"
            "Bash(mv:*)"
            "Bash(cp:*)"
            "Bash(chmod:*)"
            "Bash(mkdir:*)"
            "Bash(ls:*)"
            "Bash(cd:*)"
            "Bash(pwd:*)"
            "Bash(echo:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(sed:*)"
            "mcp__filesystem__read_file"
            "mcp__filesystem__read_text_file"
            "mcp__filesystem__read_media_file"
            "mcp__filesystem__read_multiple_files"
            "mcp__filesystem__write_file"
            "mcp__filesystem__edit_file"
            "mcp__filesystem__create_directory"
            "mcp__filesystem__list_directory"
            "mcp__filesystem__list_directory_with_sizes"
            "mcp__filesystem__directory_tree"
            "mcp__filesystem__move_file"
            "mcp__filesystem__search_files"
            "mcp__filesystem__get_file_info"
            "mcp__filesystem__list_allowed_directories"

            # === Git & Version Control ===
            "Bash(git add:*)"
            "Bash(git commit:*)"
            "Bash(git status:*)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "mcp__octocode__githubSearchCode"
            "mcp__octocode__githubGetFileContent"
            "mcp__octocode__githubViewRepoStructure"
            "mcp__octocode__githubSearchRepositories"

            # === Development Tools & Search ===
            "mcp__context7__resolve-library-id"
            "mcp__context7__get-library-docs"
            "mcp__deepwiki__read_wiki_structure"
            "mcp__deepwiki__read_wiki_contents"
            "mcp__deepwiki__ask_question"
            "mcp__ddg__duckduckgo_web_search"

            # === NixOS & Package Management ===
            "mcp__nixos-mcp__nixos_search"
            "mcp__nixos-mcp__nixos_info"
            "mcp__nixos-mcp__nixos_channels"
            "mcp__nixos-mcp__nixos_stats"
            "mcp__nixos-mcp__home_manager_search"
            "mcp__nixos-mcp__home_manager_info"
            "mcp__nixos-mcp__home_manager_stats"
            "mcp__nixos-mcp__home_manager_list_options"
            "mcp__nixos-mcp__home_manager_options_by_prefix"
            "mcp__nixos-mcp__darwin_search"
            "mcp__nixos-mcp__darwin_info"
            "mcp__nixos-mcp__darwin_stats"
            "mcp__nixos-mcp__darwin_list_options"
            "mcp__nixos-mcp__darwin_options_by_prefix"
            "mcp__nixos-mcp__nixos_flakes_stats"
            "mcp__nixos-mcp__nixos_flakes_search"
            "mcp__nixos-mcp__nixhub_package_versions"
            "mcp__nixos-mcp__nixhub_find_version"

            # === Knowledge & Memory Management ===
            "mcp__sequential-thinking__sequentialthinking"
            "mcp__memory__create_entities"
            "mcp__memory__create_relations"
            "mcp__memory__add_observations"
            "mcp__memory__delete_entities"
            "mcp__memory__delete_observations"
            "mcp__memory__delete_relations"
            "mcp__memory__read_graph"
            "mcp__memory__search_nodes"
            "mcp__memory__open_nodes"

            # === GitHub MCP Server Tools ===
            "mcp__octocode__githubSearchCode"
            "mcp__octocode__githubGetFileContent"
            "mcp__octocode__githubViewRepoStructure"
            "mcp__octocode__githubSearchRepositories"

            # === Figma MCP Server Tools ===
            "mcp__filesystem__read_file"
            "mcp__filesystem__read_text_file"
            "mcp__filesystem__read_media_file"
            "mcp__filesystem__read_multiple_files"
            "mcp__filesystem__write_file"
            "mcp__filesystem__edit_file"
            "mcp__filesystem__create_directory"
            "mcp__filesystem__list_directory"
            "mcp__filesystem__list_directory_with_sizes"
            "mcp__filesystem__directory_tree"
            "mcp__filesystem__move_file"
            "mcp__filesystem__search_files"
            "mcp__filesystem__get_file_info"
            "mcp__filesystem__list_allowed_directories"

            # === Supabase MCP Server Tools ===
            "Bash(npx)"
            "Bash(uvx)"
            "Bash(pipx)"
            "Bash(supabase-mcp-server)"

            # === Playwright MCP Server Tools ===
            "Bash(npx)"
            "Bash(docker)"
            "WebFetch"
          ];
          ask = [
            "Bash(git push:*)"
          ];
          deny = [];
          defaultMode = "plan";
        };

        agents = {
          code-reviewer = ''
            ---
            name: code-reviewer
            description: Specialized code review agent
            tools: Read, Edit, Grep
            ---

            You are a senior software engineer specializing in code reviews.
            Focus on code quality, security, and maintainability.
          '';
          documentation = ''
            ---
            name: documentation
            description: Documentation writing assistant
            model: claude-3-5-sonnet-20241022
            tools: Read, Write, Edit
            ---

            You are a technical writer who creates clear, comprehensive documentation.
            Focus on user-friendly explanations and examples.
          '';
          pre-commit = ''
            ---
            name: pre-commit
            description: Invoke after changing sources locally, and only if git-hooks.nix is used by Nix.
            tools: Bash
            ---
            # Pre-commit Quality Check Agent

            ## Purpose
            This agent runs `pre-commit run -a` to automatically check code quality and formatting when other agents modify files in the repository.

            ## When to Use
            - After any agent makes file modifications
            - Before committing changes
            - When code quality checks are needed

            ## Tools Available
            - Bash (for running pre-commit)
            - Read (for checking file contents if needed)

            ## Typical Workflow
            1. Run `pre-commit run -a` to check all files
            2. Report any issues found
            3. Suggest fixes if pre-commit hooks fail
            4. Re-run after fixes are applied

            ## Example Usage
            ```bash
            pre-commit run -a
            ```

            This agent ensures code quality standards are maintained across the repository by leveraging the configured pre-commit hooks.
          '';

          code-index = ''
            Act as a coding agent with MCP capabilities and use only the installed default code-index-mcp server for code indexing, search, file location, and structural analysis. Prefer tool-driven operations over blind page-by-page scanning to reduce tokens and time. On first entering a directory or whenever the index is missing or stale, immediately issue: Please set the project path to , where defaults to the current working directory unless otherwise specified, to create or repair the index. After initialization, consistently use these tools: set_project_path (set/switch the index root), find_files (glob discovery, e.g., src/**/*.tsx), search_code_advanced (regex/fuzzy/file-pattern constrained cross-file search), get_file_summary (per-file structure/interface summary), and refresh_index (rebuild after refactors or bulk edits). Bias retrieval and understanding toward C/C++/Rust/TS/JS: default file patterns include *.c, *.cpp, *.h, *.hpp, *.rs, *.ts, *.tsx, *.js, *.jsx; first narrow with find_files, then use search_code_advanced; when understanding a specific file, call get_file_summary. Automatically run refresh_index after modifications, dependency updates, or large renames; if file watching isn’t available, prompt for a manual refresh to keep results fresh and accurate. For cross-language scenarios (e.g., C++↔Rust bindings, TS referencing native extensions), search in batches by language priority and merge results into an actionable plan with explicit file lists.Refresh the index after modifying the file to synchronize the status.
          '';
        };

        commands = {
          changelog = ''
            ---
            allowed-tools: Bash(git log:*), Bash(git diff:*)
            argument-hint: [version] [change-type] [message]
            description: Update CHANGELOG.md with new entry
            ---
            Parse the version, change type, and message from the input
            and update the CHANGELOG.md file accordingly.
          '';
          commit = ''
            ---
            allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
            description: Create a git commit with proper message
            ---
            ## Context

            - Current git status: !`git status`
            - Current git diff: !`git diff HEAD`
            - Recent commits: !`git log --oneline -5`

            ## Task

            Based on the changes above, create a single atomic git commit with a descriptive message.
          '';
          fix-issue = ''
            ---
            allowed-tools: Bash(git status:*), Read
            argument-hint: [issue-number]
            description: Fix GitHub issue following coding standards
            ---
            Fix issue #$ARGUMENTS following our coding standards and best practices.
          '';
          ci = ''
            ---
            name: ci
            description: Run local CI using omnix
            ---

            This command runs local continuous integration checks using omnix.

            **IMPORTANT**: `om ci` will run full CI, thus takes a lot of time. Use only when necessary.

            Steps:
            1. Run `om ci` to execute all CI checks locally

            This will:
            - Build all flake outputs, which includes:
                - Run tests
                - Check formatting
                - Validate flake structure
                - Perform other CI validations

            Prerequisites:
            - Must be in a flake-enabled project directory
            - omnix (`om`) must be available in the environment
          '';
          hack = ''
            ---
            name: hack
            description: Implement a GitHub issue end-to-end until CI passes
            args:
              - name: issue_url
                description: GitHub issue URL (e.g., https://github.com/user/repo/issues/123)
                required: true
              - name: plan_mode
                description: Whether to run in plan mode (true/false, default false)
                required: false
            ---

            This command implements a GitHub issue from start to finish, ensuring all CI checks pass.

            **Usage**: `/hack <github-issue-url> [plan_mode]`

            **What it does**:
            1. Fetches the GitHub issue details using `gh` CLI
            2. Analyzes the issue requirements and creates an implementation plan
            3. If plan_mode=true, presents plan for approval before implementing
            4. Implements the requested feature or fix
            5. Creates a commit with proper issue reference
            6. Runs `om ci` to validate the implementation
            7. Iterates and fixes any CI failures until all checks pass

            **Workflow**:
            1. Parse the GitHub issue URL to extract repository and issue number
            2. Use `gh api` to fetch issue title, description, and labels
            3. Create a detailed implementation plan based on issue requirements
            4. Implement the solution step by step
            5. Commit changes with concise description
            6. Run `om ci` and analyze any failures
            7. Fix CI issues and re-run until all checks pass
            8. Provide final status report

            **Prerequisites**:
            - GitHub CLI (`gh`) must be authenticated
            - Must be in a git repository with a non-mainline branch
            - omnix (`om`) must be available for CI checks
            - Repository must have CI configured via omnix

            **Error handling**:
            - Validates GitHub URL format
            - Handles GitHub API errors gracefully
            - Provides detailed feedback on CI failures
            - Supports iterative fixing until CI passes

            **Examples**:
            ```
            /hack https://github.com/myorg/myproject/issues/42
            /hack https://github.com/myorg/myproject/issues/42 true
            ```

            First example directly implements issue #42. Second example creates a plan first and waits for approval before implementing.

          '';
          k8s-pag = ''
            ---
            name: k8s-pag
            description: Manage PAG development environment in Kubernetes
            args:
              - name: action
                description: Action to perform (setup|destroy|status|logs|shell)
                required: true
              - name: extra
                description: Additional arguments for the action
                required: false
            ---

            Manage the PAG (Prometheus + Alertmanager + Grafana) development environment using Kubernetes.

            **Usage**: `/k8s-pag <action> [extra]`

            **Actions**:
            - `setup`: Initialize the Kubernetes development environment
            - `destroy`: Clean up the development environment
            - `status`: Check the status of all components
            - `logs <pod>`: View logs for a specific pod
            - `shell <pod>`: Get shell access to a specific pod

            **Prerequisites**:
            - Docker must be running
            - kubectl must be configured
            - Helm and Kustomize must be available

            **Examples**:
            ```
            /k8s-pag setup                    # Set up the environment
            /k8s-pag status                   # Check status
            /k8s-pag logs prometheus-operator # View logs
            /k8s-pag destroy                  # Clean up
            ```
          '';
        };
      };
    };
  };
}
