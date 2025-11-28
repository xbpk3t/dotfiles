---
name: context-search-strategy
description: Strategic guidelines for context search commands
type: search-guideline
---

# Context Search Strategy

## ⚡ Execution Environment

**CRITICAL**: All commands execute in **Bash environment** (Git Bash on Windows, Bash on Linux/macOS/WSL)

**❌ Forbidden**: Windows-specific commands (`findstr`, `dir`, `where`, `type`, `copy`, `del`) - Use Bash equivalents (`grep`, `find`, `which`, `cat`, `cp`, `rm`)

## ⚡ Core Search Tools

**rg (ripgrep)**: Fast content search with regex support
**find**: File/directory location by name patterns
**grep**: Built-in pattern matching in files

### Decision Principles
- **Use rg for content** - Fastest for searching within files
- **Use find for files** - Locate files/directories by name
- **Use grep sparingly** - Only when rg unavailable
- **Always use Bash commands** - NEVER use Windows cmd/PowerShell commands

### Quick Command Reference
```bash
# Content Search (rg preferred)
rg "pattern" --type js          # Search in JS files
rg -i "case-insensitive"        # Ignore case
rg -n "show-line-numbers"       # Show line numbers
rg -A 3 -B 3 "context-lines"    # Show 3 lines before/after
rg --files-with-matches "pattern"  # Only show filenames

# File Search (find)
find . -name "*.ts" -type f     # Find TypeScript files
find . -path "*/node_modules" -prune -o -name "*.js" -print  # Exclude node_modules
find . -type d -name "components"  # Find directories

# Built-in alternatives
grep -r "pattern" .             # Recursive search (slower)
grep -n -i "pattern" file.txt   # Line numbers, case-insensitive
grep -l "pattern" *.js          # Only show filenames
```

### Workflow Integration Examples
```bash
# Search for task definitions
rg "IMPL-\d+" .workflow/ --type json        # Find task IDs
find .workflow/ -name "*.json" -path "*/.task/*"  # Locate task files

# Analyze workflow structure
rg "status.*pending" .workflow/.task/      # Find pending tasks
rg "depends_on" .workflow/.task/ -A 2      # Show dependencies

# Find workflow sessions
find .workflow/ -name ".active-*"          # Active sessions
rg "WFS-" .workflow/ --type json           # Session references

# Content analysis for planning
rg "flow_control" .workflow/ -B 2 -A 5     # Flow control patterns
find . -name "IMPL_PLAN.md" -exec grep -l "requirements" {} \;

# Code structure discovery
rg "class|interface|function" --type ts --files-with-matches  # Find definitions
find src -type f -name "*.ts" | wc -l     # Count TypeScript files
```

### Performance Tips
- **rg > grep** for content search (much faster)
- **Use --type filters** to limit file types (`--type js`, `--type py`)
- **Exclude common dirs**: `--glob '!node_modules'`, `--glob '!.git'`
- **Use -F for literal** strings (no regex overhead)
- **Use --files** to list files first, then pipe to other commands
- **Combine with other tools**: `rg "pattern" --files-with-matches | xargs wc -l`

### Common Search Patterns
```bash
# Find all imports of a module
rg "import.*from.*auth" --type ts

# Find function definitions
rg "function\s+\w+" --type js -n

# Find TODO comments
rg "TODO|FIXME" -i

# Find configuration files
find . -name "*.config.js" -o -name "*.config.ts"

# Search in specific directories only
rg "pattern" src/ tests/

# Search excluding test files
rg "pattern" --glob '!*.test.*'
```
