# NVF Neovim 使用指南

本文档详细说明了如何使用基于 NVF (Neovim from Flake) 配置的 Neovim 编辑器。

## 目录

- [基本信息](#基本信息)
- [启动 Neovim](#启动-neovim)
- [核心功能](#核心功能)
- [快捷键速查表](#快捷键速查表)
- [插件功能详解](#插件功能详解)
- [常见问题](#常见问题)

---

## 基本信息

### 什么是 NVF？

NVF (Neovim from Flake) 是一个基于 Nix 的模块化 Neovim 配置框架，它提供：

- 声明式配置
- 可重现的开发环境
- 模块化插件管理
- 与 Nix 生态系统的深度集成

### Leader 键

本配置中的 Leader 键默认为 **空格键** (`<Space>`)。

---

## 启动 Neovim

在终端中输入以下任一命令：

```bash
nvim          # 启动 Neovim
vim           # 别名，等同于 nvim
vi            # 别名，等同于 nvim
```

---

## 核心功能

### 1. Scratches（临时文件）

类似 IDEA 的 Scratches 功能，用于创建临时文件进行快速测试和笔记。

**注意**：由于 scratch.nvim 插件需要特殊配置，当前配置中暂未完全集成。您可以使用以下替代方案：

- 使用 `:e /tmp/scratch.txt` 创建临时文件
- 使用 `:enew` 创建新的空缓冲区

### 2. Monokai Pro 主题

已启用 Monokai Pro 主题，提供类似 IDEA Monokai 的高亮配色方案。

**主题变体**：

- `pro` (默认)
- `classic`
- `octagon`
- `machine`
- `ristretto`
- `spectrum`

**切换主题**：编辑 `home/base/core/nvf.nix` 中的 `filter` 选项。

### 3. 文件树 Git 状态

Neo-tree 文件浏览器已启用，支持显示 Git 状态：

- 🟢 新增文件
- 🟡 修改文件
- 🔴 删除文件
- 📝 未跟踪文件

**快捷键**：`<leader>fe` 切换文件树

### 4. 最近文件（类似 CMD+E）

使用 Telescope 快速访问最近编辑的文件。

**快捷键**：`<leader>fr`

### 5. 数据库支持

集成了 vim-dadbod 系列插件，支持多种数据库：

- MySQL/MariaDB
- PostgreSQL
- SQLite
- MongoDB
- Redis

**快捷键**：`<leader>D` 打开数据库 UI

**连接数据库示例**：

```vim
:DB g:db = 'mysql://user:password@localhost/dbname'
:DB SELECT * FROM users;
```

### 6. 批量查找和替换

使用 Spectre 插件进行项目级别的批量查找和替换，支持正则表达式。

**快捷键**：`<leader>sr`

**使用步骤**：

1. 按 `<leader>sr` 打开 Spectre
2. 输入搜索内容
3. 输入替换内容
4. 按 `<leader>rc` 执行替换

### 7. TODO 注释过滤

todo-comments 插件自动高亮和搜索代码中的 TODO 注释。

**支持的关键字**：

- `TODO` - 待办事项
- `FIXME` / `BUG` - 需要修复的问题
- `HACK` - 临时解决方案
- `WARN` / `WARNING` - 警告
- `PERF` / `OPTIMIZE` - 性能优化
- `NOTE` / `INFO` - 注释说明

**快捷键**：`<leader>ft` 搜索所有 TODO 注释

### 8. 多项目支持

project-nvim 插件支持管理和切换多个项目。

**快捷键**：`<leader>fp` 切换项目

**功能**：

- 自动检测项目根目录（基于 .git、package.json 等）
- 记住最近访问的项目
- 快速切换项目

### 9. 调试支持（DAP）

集成了 nvim-dap 和 nvim-dap-ui，提供类似 IDEA 的调试功能。

**调试快捷键**：

- `<F5>` - 继续执行
- `<F10>` - 单步跳过
- `<F11>` - 单步进入
- `<F12>` - 单步跳出
- `<leader>b` - 切换断点
- `<leader>du` - 切换调试 UI

**设置断点**：

1. 将光标移到要设置断点的行
2. 按 `<leader>b`
3. 按 `<F5>` 开始调试

---

## 快捷键速查表

### 基本操作

| 快捷键       | 模式     | 功能           |
| ------------ | -------- | -------------- |
| `jk`         | 插入模式 | 退出到普通模式 |
| `<leader>nh` | 普通模式 | 清除搜索高亮   |

### 文件操作

| 快捷键       | 功能                          |
| ------------ | ----------------------------- |
| `<leader>ff` | 按文件名搜索文件              |
| `<leader>lg` | 在文件内容中搜索（live grep） |
| `<leader>fe` | 切换文件浏览器                |
| `<leader>fr` | 打开最近文件列表              |

### 项目管理

| 快捷键       | 功能           |
| ------------ | -------------- |
| `<leader>fp` | 切换项目       |
| `<leader>ft` | 搜索 TODO 注释 |
| `<leader>sr` | 批量查找和替换 |

### 数据库

| 快捷键      | 功能          |
| ----------- | ------------- |
| `<leader>D` | 打开数据库 UI |

### 调试

| 快捷键       | 功能        |
| ------------ | ----------- |
| `<F5>`       | 继续执行    |
| `<F10>`      | 单步跳过    |
| `<F11>`      | 单步进入    |
| `<F12>`      | 单步跳出    |
| `<leader>b`  | 切换断点    |
| `<leader>du` | 切换调试 UI |

### 插入模式方向键

| 快捷键  | 功能     |
| ------- | -------- |
| `<C-h>` | 向左移动 |
| `<C-j>` | 向下移动 |
| `<C-k>` | 向上移动 |
| `<C-l>` | 向右移动 |

---

## 插件功能详解

### LSP（语言服务器协议）

已启用以下语言的 LSP 支持：

- **Nix** - Nix 语言
- **C/C++** - Clang
- **Python** - Python
- **Markdown** - Markdown
- **TypeScript/JavaScript** - TS
- **HTML** - HTML

**功能**：

- 代码补全
- 语法检查
- 跳转到定义
- 查找引用
- 重命名符号
- 保存时自动格式化

### Telescope（模糊查找器）

强大的模糊查找工具，支持：

- 文件搜索
- 内容搜索
- 最近文件
- Git 文件
- 命令历史
- 帮助文档

### Neo-tree（文件浏览器）

功能丰富的文件浏览器：

- 树形目录结构
- Git 状态显示
- 文件操作（创建、删除、重命名）
- 书签功能

### Which-Key

自动显示可用的快捷键提示。按下 Leader 键后稍等片刻，会显示所有可用的快捷键组合。

### GitSigns

在行号旁显示 Git 变更标记：

- `+` 新增行
- `~` 修改行
- `-` 删除行

### Treesitter

提供更好的语法高亮和代码理解：

- 精确的语法高亮
- 代码折叠
- 增量选择
- 上下文显示

---

## 常见问题

### Q: 如何查看所有可用的快捷键？

A: 按下 `<Space>` (Leader 键) 后稍等片刻，Which-Key 会自动显示所有可用的快捷键。

### Q: 如何更改主题？

A: 编辑 `home/base/core/nvf.nix` 文件，修改 Monokai Pro 配置中的 `filter` 选项，然后运行 `task build-switch` 重新构建。

### Q: 数据库连接信息如何保存？

A: 可以在 `~/.config/nvim/db_ui.lua` 中配置数据库连接，或使用 `:DB` 命令临时连接。

### Q: 如何添加新的语言支持？

A: 编辑 `home/base/core/nvf.nix` 文件，在 `languages` 部分添加相应语言的配置，然后运行 `task build-switch`。

### Q: 调试器不工作怎么办？

A: 确保已安装相应语言的调试适配器。例如，Python 需要 `debugpy`，Node.js 需要 `node-debug2`。

### Q: 如何禁用某个插件？

A: 编辑 `home/base/core/nvf.nix` 文件，将相应插件的 `enable` 设置为 `false`，或从 `startPlugins` 列表中移除，然后运行 `task build-switch`。

---

## 进阶技巧

### 1. 自定义快捷键

在 `home/base/core/nvf.nix` 的 `keymaps` 部分添加新的快捷键映射。

### 2. 添加自定义插件

在 `startPlugins` 列表中添加新的插件，并在 `luaConfigRC` 中配置。

### 3. 配置数据库连接

创建 `~/.local/share/db_ui/connections.json` 文件：

```json
{
  "mysql_local": "mysql://root:password@localhost/mydb",
  "postgres_dev": "postgresql://user:pass@localhost/devdb"
}
```

### 4. 项目特定配置

在项目根目录创建 `.nvim.lua` 文件，添加项目特定的配置。

---

## 获取帮助

- 在 Neovim 中输入 `:help` 查看帮助文档
- 输入 `:checkhealth` 检查配置状态
- 查看 NVF 官方文档：https://github.com/NotAShelf/nvf

---

## 总结

本 NVF 配置提供了类似 IDEA 的强大功能：

✅ **Scratches** - 临时文件支持（通过 `:enew` 或 `:e /tmp/scratch.txt`）
✅ **Monokai 主题** - 已启用 Monokai Pro
✅ **Git 状态** - 文件树显示 Git 状态
✅ **最近文件** - `<leader>fr` 快速访问
✅ **数据库支持** - vim-dadbod 系列插件
✅ **批量查找替换** - Spectre 插件，支持正则
✅ **TODO 过滤** - todo-comments 插件
✅ **多项目支持** - project-nvim 插件
✅ **调试支持** - nvim-dap 完整调试功能

享受您的 Neovim 编辑体验！
