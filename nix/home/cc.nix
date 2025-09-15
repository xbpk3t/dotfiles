{pkgs, ...}: {
  # Claude CLI 环境变量配置
  home.sessionVariables = {
    # 自定义 API 端点，用于连接到第三方模型服务
    ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
    # API 认证令牌 - 使用 sops 管理，通过 cat 命令读取文件内容
    ANTHROPIC_AUTH_TOKEN = "$(cat /etc/claude/zai/token)";
  };

  # Shell 配置 - 添加 Claude Code 相关的 shell 功能
  programs.bash.initExtra = ''

  '';

  # Claude Code 程序配置
  programs.claude-code = {
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

      #      figma = {
      #        type = "stdio";
      #        command = "npx";
      #        args = ["-y" "figma-developer-mcp" "--stdio"];
      #      };
      #
      #      supabase = {
      #        type = "stdio";
      #        command = "supabase-mcp-server";
      #      };
      #
      #      playwright = {
      #        type = "stdio";
      #        command = "npx";
      #        args = ["@playwright/mcp@latest"];
      #      };
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
    };
  };
}
