# flomo-cleaner

用于清空当前 `flomo /mine` 列表的 Tampermonkey 脚本，包含可复用的 E2E 自动化验证闭环。

## 当前结构

- 工作区根目录：`.tms`
- 脚本包目录：`.tms/packages/flomo-cleaner`
- E2E 与 profile 初始化：`.tms/e2e`
- 统一任务入口：`.tms/Taskfile.yml`

## 快速开始

在仓库根目录执行：

```bash
task -t .tms/Taskfile.yml install
task -t .tms/Taskfile.yml verify
```

## 构建并同步到 Tampermonkey

```bash
task -t .tms/Taskfile.yml setup:flomo-profile
```

这个命令会执行三件事：
1. 构建 `dist/flomo-cleaner.user.js`。
2. 向 Tampermonkey 安装或更新脚本内容。
3. 复用共享的持久化 Chrome profile 做 flomo 验证。

## 人工使用方式

1. 打开 `https://v.flomoapp.com/mine`。
2. 打开 Tampermonkey 扩展菜单。
3. 执行菜单命令：`清空当前 flomo 笔记`。

执行 destructive 删除前，脚本会弹确认框。

## 自动化验证方式

非破坏性检查：

```bash
task -t .tms/Taskfile.yml e2e:flomo
```

破坏性端到端流程（发布测试 memo、执行清理、reload 后验证）：

```bash
task -t .tms/Taskfile.yml e2e:flomo:run
```

## 使用路径说明

- 人工路径：通过 Tampermonkey 菜单命令 `清空当前 flomo 笔记` 执行。
- 自动化路径：Playwright 调用 `window.__flomoCleaner.probe()` 和 `run()`，并在页面 reload 后验证真实状态。

## 安全说明

- `e2e:flomo:run` 会对当前 `/mine` 列表执行 destructive 操作。
- 删除动作会进入 flomo Trash，不是永久清空。
- destructive 流程应保持显式命令触发，不要默认自动执行。

## 常见故障排查

`userscript hook missing: window.__flomoCleaner`
- 重新执行 `task -t .tms/Taskfile.yml setup:flomo-profile`。
- 确认 Tampermonkey 脚本已启用，且 match 包含 `https://v.flomoapp.com/mine*`。

Playwright 打开的是登录页而不是 `/mine`
- 持久化 profile 的登录态过期。
- 重新执行 `setup:flomo-profile`，完成登录后再跑 E2E。

`run` 在选择/删除步骤失败
- flomo 页面 DOM 或菜单文案可能已变化。
- 回查 `src/flomo.ts` 中的 selector 和菜单文本匹配逻辑。
