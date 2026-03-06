# MCP Tool Strategy: Triggers & Workflows

## ⚡ Triggering Mechanisms

**Auto-Trigger Scenarios**:
- User mentions "exa-code" or code-related queries → `mcp__exa__get_code_context_exa`
- Need current web information → `mcp__exa__web_search_exa`
- Finding code patterns/files → `mcp__code-index__search_code_advanced`
- Locating specific files → `mcp__code-index__find_files`

**Manual Trigger Rules**:
- Complex API research → Exa Code Context
- Architecture pattern discovery → Exa Code Context + Codex analysis
- Real-time information needs → Exa Web Search
- Codebase exploration → Code Index tools first, then Codex analysis

## 🎯 Available MCP Tools

### Exa Code Context (mcp__exa__get_code_context_exa)
**Purpose**: Search and get relevant context for programming tasks
**Strengths**: Highest quality context for libraries, SDKs, and APIs
**Best For**: Code examples, API patterns, learning frameworks

**Usage**:
```bash
mcp__exa__get_code_context_exa(
  query="React useState hook examples",
  tokensNum="dynamic"  # or 1000-50000
)
```

**Examples**: "React useState", "Python pandas filtering", "Express.js middleware"

### Exa Web Search (mcp__exa__web_search_exa)
**Purpose**: Real-time web searches with content scraping
**Best For**: Current information, research, recent solutions

**Usage**:
```bash
mcp__exa__web_search_exa(
  query="latest React 18 features",
  numResults=5  # default: 5
)
```


### Code Index Tools (mcp__code-index__)
**核心方法**: `search_code_advanced`, `find_files`, `refresh_index`

**核心搜索**:
```bash
mcp__code-index__search_code_advanced(pattern="function.*auth", file_pattern="*.ts")
mcp__code-index__find_files(pattern="*.test.js")
mcp__code-index__refresh_index()  # git操作后刷新
```

**实用场景**:
- **查找代码**: `search_code_advanced(pattern="old.*API")`
- **定位文件**: `find_files(pattern="src/**/*.tsx")`
- **更新索引**: `refresh_index()` (git操作后)

**文件搜索测试结果**:
- ✅ `find_files(pattern="*.md")` - 搜索所有 Markdown 文件
- ✅ `find_files(pattern="*complete*")` - 通配符匹配文件名
- ❌ `find_files(pattern="complete.md")` - 精确匹配可能失败
- 📝 建议使用通配符模式获得更好的搜索结果

## 📊 Tool Selection Matrix

| Task | MCP Tool | Use Case | Integration |
|------|----------|----------|-------------|
| **Code Context** | Exa Code | API examples, patterns | → Codex analysis |
| **Research** | Exa Web | Current info, trends | → Planning phase |
| **Code Search** | Code Index | Pattern discovery, file location | → Codex analysis |
| **Navigation** | Code Index | File exploration, structure | → Architecture phase |

## 🚀 Integration Patterns

### Standard Workflow
```bash
# 1. Explore codebase structure
mcp__code-index__find_files(pattern="*async*")
mcp__code-index__search_code_advanced(pattern="async.*function", file_pattern="*.ts")

# 2. Get external context
mcp__exa__get_code_context_exa(query="TypeScript async patterns", tokensNum="dynamic")

# 3. Analyze and implement with Codex
mcp__codex__codex(
  model="gpt-5-codex",
  sandbox="danger-full-access",
  approval_policy="on-failure",
  prompt="""
PURPOSE: Understand and improve async patterns
TASK: Analyze current async implementation and apply modern patterns
MODE: auto
CONTEXT: Code index results + Exa context + @{src/async/**/*}
EXPECTED: Pattern analysis and implementation improvements
RULES: Focus on TypeScript best practices, maintain backward compatibility
"""
)
```

### Enhanced Planning
1. **Explore codebase** with Code Index tools
2. **Research** with Exa Web Search
3. **Get code context** with Exa Code Context
4. **Analyze & Implement** with Codex

## 🔧 Best Practices

### Code Index
- **Search first** - Use before external tools for codebase exploration
- **Refresh after git ops** - Keep index synchronized
- **Pattern specificity** - Use precise regex patterns for better results
- **File patterns** - Combine with glob patterns for targeted search
- **Glob pattern matching** - Use `*.md`, `*complete*` patterns for file discovery
- **Exact vs wildcard** - Exact names may fail, use wildcards for better results

### Exa Code Context
- **Use "dynamic" tokens** for efficiency
- **Be specific** - include technology stack
- **MANDATORY** when user mentions exa-code or code queries

### Exa Web Search
- **Default 5 results** usually sufficient
- **Use for current info** - supplement knowledge cutoff



## 🎯 Common Scenarios

### Learning New Technology
```bash
# Explore existing patterns + get examples + research + analyze
mcp__code-index__search_code_advanced(pattern="router|routing", file_pattern="*.ts")
mcp__exa__get_code_context_exa(query="Next.js 14 app router", tokensNum="dynamic")
mcp__exa__web_search_exa(query="Next.js 14 best practices 2024", numResults=3)

# Analyze and learn with Codex
mcp__codex__codex(
  model="gpt-5-codex",
  sandbox="read-only",
  prompt="""
PURPOSE: Learn Next.js 14 app router patterns
TASK: Analyze existing router implementation and document patterns
MODE: analysis
CONTEXT: Code index results + Exa context + @{src/app/**/*}
EXPECTED: Pattern documentation and best practices
RULES: Focus on Next.js 14 app router, document findings
"""
)
```

### Debugging
```bash
# Find similar patterns + solutions + fix
mcp__code-index__search_code_advanced(pattern="similar.*error", file_pattern="*.ts")
mcp__exa__get_code_context_exa(query="TypeScript generic constraints", tokensNum="dynamic")

# Fix with Codex
mcp__codex__codex(
  model="gpt-5-codex",
  sandbox="danger-full-access",
  approval_policy="on-failure",
  prompt="""
PURPOSE: Fix TypeScript generic constraint issues
TASK: Identify and fix generic constraint problems
MODE: auto
CONTEXT: Code index results + Exa context + error logs
EXPECTED: Fixed TypeScript code with proper generic constraints
RULES: Maintain type safety, follow TypeScript best practices
"""
)
```

### Codebase Exploration
```bash
# Comprehensive codebase understanding workflow
mcp__code-index__set_project_path(path="/current/project")  # 设置项目路径
mcp__code-index__refresh_index()  # 刷新索引
mcp__code-index__find_files(pattern="*auth*")  # Find auth-related files
mcp__code-index__search_code_advanced(pattern="function.*auth", file_pattern="*.ts")  # Find auth functions
mcp__code-index__get_file_summary(file_path="src/auth/index.ts")  # Understand structure

# Analyze architecture with Codex
mcp__codex__codex(
  model="gpt-5-codex",
  sandbox="read-only",
  prompt="""
PURPOSE: Analyze authentication system architecture
TASK: Review auth implementation and identify improvement areas
MODE: analysis
CONTEXT: Code index results + @{src/auth/**/*}
EXPECTED: Architecture analysis report with recommendations
RULES: Focus on security, maintainability, and scalability
"""
)
```

### Project Setup Workflow
```bash
# 新项目初始化流程
mcp__code-index__set_project_path(path="/path/to/new/project")
mcp__code-index__get_settings_info()  # 确认设置
mcp__code-index__refresh_index()  # 建立索引
mcp__code-index__configure_file_watcher(enabled=true)  # 启用文件监控
mcp__code-index__get_file_watcher_status()  # 确认监控状态
```

## ⚡ Performance Tips

- **Code Index first** → explore codebase before external tools
- **Use "dynamic" tokens** for Exa Code Context
- **MCP first** → gather context before analysis
- **Focus queries** - avoid overly broad searches
- **Integrate selectively** - use relevant context only
- **Refresh index** after major git operations
- **Use Codex for analysis** → sequential-thinking for deep reasoning
