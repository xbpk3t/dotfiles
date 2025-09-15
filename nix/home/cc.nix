{pkgs, ...}: {
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
          "WebFetch(domain:docs.anthropic.com)"
          "Bash(rm:*)"
          "WebFetch(domain:github.com)"

          "Bash(grep:*)"
          "Bash(git add:*)"

          "Bash(mv:*)"
          "Bash(sed:*)"

          "Bash(find:*)"
          "Bash(rg:*)"
          "Bash(git commit:*)"
          "Bash(git status:*)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "WebFetch(domain:api.github.com)"
          "WebFetch"
          "Bash(chmod:*)"
          "Bash(mkdir:*)"
          "Bash(cp:*)"
          "Bash(ls:*)"
          "Bash(cd:*)"
          "Bash(pwd:*)"
          "Bash(echo:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"

          "mcp__context7__resolve-library-id"
          "mcp__context7__get-library-docs"
          "mcp__filesystem__list_directory"

          "mcp__filesystem__edit_file"
          "mcp__filesystem__search_files"

          "mcp__deepwiki__read_wiki_structure"
          "mcp__deepwiki__read_wiki_contents"
          "mcp__deepwiki__ask_question"

          "mcp__octocode__githubSearchCode"
          "mcp__octocode__githubSearchRepositories"
          "mcp__octocode__githubViewRepoStructure"
          "mcp__octocode__githubGetFileContent"

          "mcp__ddg__duckduckgo_web_search"
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

  # 添加 Claude CLI 和相关工具包
  home.packages = [
  ];

  # Claude CLI 环境变量配置
  home.sessionVariables = {
    # 自定义 API 端点，用于连接到第三方模型服务
    ANTHROPIC_BASE_URL = "https://open.bigmodel.cn/api/anthropic";
    # API 认证令牌 - 使用 sops 管理 (存储文件路径，避免时序问题)
    ANTHROPIC_AUTH_TOKEN = "/etc/claude/zai/token";
  };

  # Shell 配置 - 添加 Claude Code 相关的 shell 功能
  programs.bash.initExtra = ''
  '';
}
