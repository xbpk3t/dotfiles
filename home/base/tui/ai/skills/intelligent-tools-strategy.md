---
name: intelligent-tools-strategy
description: Strategic decision framework for Codex tool usage
type: strategic-guideline
---

# Intelligent Tools Selection Strategy

## 📋 Table of Contents
1. [Core Framework](#-core-framework)
2. [Tool Specifications](#-tool-specifications)
3. [Command Templates](#-command-templates)
4. [Usage Patterns](#-usage-patterns)
5. [Best Practices](#-best-practices)

---

## ⚡ Core Framework

### Tool Overview
- **Codex**: Development, implementation, automation & analysis

### Decision Principles
- **Use Codex for complex tasks** - Codex provides autonomous development and deep analysis
- **Default to tools** - Use specialized tools for coding tasks requiring >10 lines of logic
- **Context optimization** - Use `-C [directory]` parameter for focused analysis to reduce irrelevant context
- **⚠️ Write operation protection** - For local codebase write/modify operations, require EXPLICIT user confirmation unless user provides clear instructions containing MODE=write or MODE=auto

### Quick Decision Rules
1. **Building/Fixing?** → Use Codex
2. **Deep Analysis?** → Use Codex with sequential-thinking
3. **Architecture Review?** → Use Codex
4. **Complex Logic (>10 lines)?** → Use Codex for design

---

## 🎯 Tool Specifications

### Codex
- **Command**: `codex --full-auto exec` or via MCP `mcp__codex__codex`
- **Strengths**: Autonomous development, deep reasoning, sequential-thinking integration
- **Best For**: Implementation, testing, automation, analysis, code review
- **Permissions**: Requires explicit MODE=auto or MODE=write specification
- **Default MODE**: No default, must be explicitly specified
- **⚠️ Write Trigger**: Only when user explicitly requests "implement", "modify", "generate code" AND specifies MODE

#### MODE Options
- `auto` - ⚠️ Autonomous development with full file operations (requires explicit specification, enables -s danger-full-access)
- `write` - ⚠️ Test generation and file modification (requires explicit specification)
- **Default**: No default mode, MODE must be explicitly specified

#### Session Management
- `codex resume` - Resume previous interactive session (picker by default)
- `codex exec "task" resume --last` - Continue most recent session with new task (maintains context)
- `codex -i <image_file>` - Attach image(s) to initial prompt (useful for UI/design references)
- **Multi-task Pattern**: First task uses `exec`, subsequent tasks use `exec "..." resume --last` for context continuity
    - **Parameter Position**: `resume --last` must be placed AFTER the prompt string at command END
    - **Example**:
      ```bash
      # First task - establish session
      codex -C project --full-auto exec "Implement auth module" --skip-git-repo-check -s danger-full-access

      # Subsequent tasks - continue same session
      codex --full-auto exec "Add JWT validation" resume --last --skip-git-repo-check -s danger-full-access
      codex --full-auto exec "Write auth tests" resume --last --skip-git-repo-check -s danger-full-access
      ```

#### Auto-Resume Decision Rules
**When to use `resume --last`**:
- Current task is related to/extends previous Codex task in conversation memory
- Current task requires context from previous implementation
- Current task is part of multi-step workflow (e.g., implement → enhance → test)
- Session memory indicates recent Codex execution on same module/feature

**When NOT to use `resume --last`**:
- First Codex task in conversation
- New independent task unrelated to previous work
- Switching to different module/feature area
- No recent Codex task in conversation memory

---

## 🎯 Command Templates

### Universal Template Structure
Every command MUST follow this structure:
- [ ] **PURPOSE** - Clear goal and intent
- [ ] **TASK** - Specific execution task
- [ ] **MODE** - Execution mode and permission level
- [ ] **CONTEXT** - File references and memory context from previous sessions
- [ ] **EXPECTED** - Clear expected results
- [ ] **RULES** - Constraints and guidelines

### Standard Command Formats

#### Codex CLI Commands
```bash
# Codex Development (requires explicit MODE=auto)
# NOTE: --skip-git-repo-check and -s danger-full-access must be placed at command END
codex -C [directory] --full-auto exec "
PURPOSE: [clear development goal]
TASK: [specific development task]
MODE: auto
CONTEXT: [file references and memory context]
EXPECTED: [expected deliverables]
RULES: [constraints and guidelines]
" --skip-git-repo-check -s danger-full-access

# Codex Test/Write Mode (requires explicit MODE=write)
# NOTE: --skip-git-repo-check and -s danger-full-access must be placed at command END
codex -C [directory] --full-auto exec "
PURPOSE: [clear goal]
TASK: [specific task]
MODE: write
CONTEXT: [file references and memory context]
EXPECTED: [expected deliverables]
RULES: [constraints and guidelines]
" --skip-git-repo-check -s danger-full-access
```

#### Codex MCP Commands
```python
# Via MCP (preferred in Claude Code)
mcp__codex__codex(
  model="gpt-5-codex",  # or "o3", "o4-mini"
  sandbox="danger-full-access",  # or "workspace-write", "read-only"
  approval_policy="on-failure",  # or "never", "untrusted"
  prompt="""
[TASK_MARKER: YYYYMMDD-HHMMSS-XXXX]

PURPOSE: [clear development goal]
TASK: [specific development task]
MODE: auto
CONTEXT: [file references and memory context]
EXPECTED: [expected deliverables]
RULES: [constraints and guidelines]

[在响应末尾附加 conversationId]
"""
)

# Continue conversation
mcp__codex__codex_reply(
  conversationId="<previous_conversation_id>",
  prompt="[next task or question]"
)
```

### Directory Context Configuration
- **Codex CLI**: `codex -C path/to/project --full-auto exec "task"` (Codex supports -C)
- **Path types**: Supports both relative (`../project`) and absolute (`/full/path`) paths

### File Pattern Reference
- All files: `@{**/*}` or describe as "all files in the project"
- Source files: `@{src/**/*}` or "all source files"
- TypeScript: `@{*.ts,*.tsx}` or "all TypeScript files"
- With docs: `@{CLAUDE.md,**/*CLAUDE.md}` or "CLAUDE.md and all CLAUDE.md files"
- Tests: `@{src/**/*.test.*}` or "all test files"

**Complex Pattern Discovery**:
For complex file pattern requirements, use semantic discovery tools BEFORE CLI execution:
- **rg (ripgrep)**: Content-based file discovery with regex patterns
- **Code Index MCP**: Semantic file search based on task requirements
- **Workflow**: Discover → Extract precise paths → Build CONTEXT field

**Example**:
```bash
# Step 1: Discover files semantically
rg "export.*Component" --files-with-matches --type ts  # Find component files
mcp__code-index__search_code_advanced(pattern="interface.*Props", file_pattern="*.tsx")  # Find interface files

# Step 2: Build precise CONTEXT from discovery results
CONTEXT: @{src/components/Auth.tsx,src/types/auth.d.ts,src/hooks/useAuth.ts}

# Step 3: Execute Codex with precise file references
codex -C src --full-auto exec "
PURPOSE: Analyze authentication components
TASK: Review auth component patterns and props interfaces
MODE: auto
CONTEXT: @{components/Auth.tsx,types/auth.d.ts,hooks/useAuth.ts}
EXPECTED: Pattern analysis and improvement suggestions
RULES: Focus on type safety and component composition
" --skip-git-repo-check -s danger-full-access
```

---

## 🚀 Usage Patterns

### Workflow Integration (REQUIRED)
When planning any coding task, integrate Codex appropriately:

1. **Understanding Phase**: Use Codex for analysis with sequential-thinking
2. **Architecture Phase**: Use Codex for design and analysis
3. **Implementation Phase**: Use Codex for development
4. **Quality Phase**: Use Codex for testing and validation

### Common Scenarios

#### Feature Development (Multi-task with Resume)
```bash
# First task - establish session
codex -C path/to/project --full-auto exec "
PURPOSE: Implement user authentication
TASK: Create JWT-based authentication system
MODE: auto
CONTEXT: @{src/auth/**/*} Database schema from session memory
EXPECTED: Complete auth module with tests
RULES: Follow security best practices, use TypeScript
" --skip-git-repo-check -s danger-full-access

# Continue in same session - Add JWT validation
codex --full-auto exec "
PURPOSE: Enhance authentication security
TASK: Add JWT token validation and refresh logic
MODE: auto
CONTEXT: Previous auth implementation from current session
EXPECTED: JWT validation middleware and token refresh endpoints
RULES: Follow JWT best practices, maintain session context
" resume --last --skip-git-repo-check -s danger-full-access

# Continue in same session - Add tests
codex --full-auto exec "
PURPOSE: Increase test coverage
TASK: Generate comprehensive tests for auth module
MODE: write
CONTEXT: Auth implementation from current session
EXPECTED: Complete test suite with 80%+ coverage
RULES: Use Jest, follow existing patterns
" resume --last --skip-git-repo-check -s danger-full-access
```

#### Interactive Session Resume
```bash
# Resume previous session with picker
codex resume

# Or resume most recent session directly
codex resume --last
```

#### MCP Integration (Claude Code)
```python
# Initial analysis
mcp__codex__codex(
  model="gpt-5-codex",
  sandbox="danger-full-access",
  approval_policy="on-failure",
  prompt="""
[TASK_MARKER: 20251026-183000-AUTH]

PURPOSE: Analyze authentication system
TASK: Review current auth implementation and identify improvements
MODE: auto
CONTEXT: @{src/auth/**/*}
EXPECTED: Analysis report with improvement suggestions
RULES: Focus on security and maintainability

[在响应末尾附加 conversationId]
"""
)

# Continue with implementation (using returned conversationId)
mcp__codex__codex_reply(
  conversationId="<extracted_conversation_id>",
  prompt="Implement the suggested improvements to auth system"
)
```

---

## 🔧 Best Practices

### General Guidelines
- **Be specific** - Clear PURPOSE, TASK, and EXPECTED fields
- **Include constraints** - File patterns, scope, requirements in RULES
- **Discover patterns first** - Use rg/MCP for complex file discovery before Codex execution
- **Build precise CONTEXT** - Convert discovery results to explicit file references
- **Document context** - Always reference CLAUDE.md for project context

### Context Optimization Strategy
**Directory Navigation**: Use `-C [directory]` pattern when analyzing specific areas to reduce irrelevant context

**When to change directory**:
- Specific directory mentioned → Use `-C directory` pattern
- Focused analysis needed → Target specific directory with -C
- Multi-directory scope → Stay in root, use explicit paths

**Example**:
```bash
# Codex - Focused implementation
codex -C src/auth --full-auto exec "
PURPOSE: Improve auth implementation
TASK: Review and enhance auth code
MODE: auto
CONTEXT: @{**/*.ts}
EXPECTED: Code improvements and fixes
RULES: Maintain backward compatibility
" --skip-git-repo-check -s danger-full-access
```

### Planning Checklist

For every development task:
- [ ] **Purpose defined** - Clear goal and intent
- [ ] **Mode selected** - Execution mode and permission level determined
- [ ] **Context gathered** - File references and session memory documented
- [ ] **Constraints specified** - File patterns, scope, requirements
- [ ] **Implementation approach** - Codex usage and workflow
- [ ] **Quality measures** - Testing and validation plan

---

## ⚙️ Execution Configuration

### Core Execution Rules
- **Dynamic Timeout (20-120min)**: Allocate execution time based on task complexity
    - Simple tasks (analysis, search): 20-40min (1200000-2400000ms)
    - Medium tasks (refactoring, documentation): 40-60min (2400000-3600000ms)
    - Complex tasks (implementation, migration): 60-120min (3600000-7200000ms)
- **Codex Multiplier**: Codex commands use 1.5x of allocated time
- **Apply to All Commands**: All bash() wrapped Codex executions
- **Auto-detect**: Analyze PURPOSE and TASK fields to determine appropriate timeout

### Permission Framework
- **⚠️ WRITE PROTECTION**: Local codebase write/modify requires EXPLICIT user confirmation
    - **Analysis Mode**: Read-only, safe for auto-execution
    - **Write Mode**: Requires user explicitly states MODE=write or MODE=auto in prompt
    - **Exception**: User provides clear instructions like "modify", "create", "implement"
- **Codex Write Access**: Use `-s danger-full-access` and `--skip-git-repo-check` ONLY when MODE=auto explicitly specified
    - **Parameter Position**: Place AFTER the prompt string at command END: `codex ... exec "..." --skip-git-repo-check -s danger-full-access`
- **Default Behavior**: Codex defaults to analysis/read-only mode without explicit write permission
