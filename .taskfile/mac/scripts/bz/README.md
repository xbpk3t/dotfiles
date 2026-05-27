# bz — Bilibili 视频字幕批处理管线

从 B 站视频 URL 列表出发，自动下载字幕、生成转录稿、并由 AI 输出结构化摘要。

```
urls.txt → [init] → [fetch (yt-dlp)] → [transcript (pysubs2)] → [summarize (AI runner)] → summary.md
```

## 依赖

- [Nushell](https://www.nushell.sh/) — 脚本运行时
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — 下载 B 站字幕
- [pysubs2](https://github.com/tkarabela/pysubs2) — 字幕格式转换
- Python 3 — 仅 `summarize` 阶段的 JSON 修复用到 `fix_json.py`

## 快速开始

```bash
# 1. 在项目根目录创建 urls.txt，每行一个 B 站视频链接
echo "https://www.bilibili.com/video/BV1XX..." > urls.txt

# 2. 一键走完 init → fetch → transcript
task bz

# 3. 用 Codex 生成结构化摘要（默认模型 gpt-5.5，默认 20 并发）
task bz CMD=summarize AGENT=codex

# 或使用 Claude Code；runner 写基础命令，脚本会自动追加 -p
task bz CMD=summarize AGENT=claude RUNNER="claude --model=deepseek-v4-flash"

# 查看管线状态
task bz CMD=status
task bz CMD=summary-status
```

## 子命令

所有命令通过 `task bz CMD=<command>` 调用，或直接 `nu run.nu <command>`。

| 命令 | 作用 |
|---|---|
| `all <urls.txt>` | init → fetch → transcript 一键执行 |
| `init <urls.txt>` | 从 urls.txt 加载视频 URL，创建工作目录和事件日志 |
| `fetch` | 对 pending 状态的视频执行 yt-dlp 下载字幕 |
| `transcript` | 对 fetched 状态的视频将字幕转为规范化的 Markdown 转录稿 |
| `summarize` | 对转录稿调用 AI runner 生成结构化摘要（JSON → summary.md） |
| `status` | 显示 fetch / transcript 阶段的任务统计 |
| `failed` | 列出 fetch / transcript 失败详情 |
| `failed-urls` | 提取所有失败视频的 URL |
| `summary-status` | 显示 summarize 阶段的任务统计 |
| `summary-failed` | 列出 summarize 失败详情 |

### 通用参数

- `--workdir <path>` — 工作目录，默认 `/tmp/bz-YYYY-MM-DD`，最新目录软链到 `/tmp/bz-latest`

### fetch 参数

- `--cookies-from-browser <browser>` — 从浏览器提取 cookies（默认 `chrome`）
- `--cookies <path>` — 直接指定 cookies.txt 文件路径

### summarize 参数

- `--agent <codex|claude|custom>` — AI runner 类型；`codex` 默认调用 `codex exec --model gpt-5.5`
- `--runner <cmd>` — 覆盖 AI runner 基础命令；不要包含 Codex 的 `-` 或 Claude 的 `-p`，脚本会按 `--agent` 自动追加
- `--concurrency <n>` — 摘要并发数，默认 `20`
- `--transcript-dir <path>` — 转录稿目录，默认 `<workdir>/transcript`
- `--out <path>` — 最终摘要输出路径，默认 `<workdir>/summary.md`
- `--prompt <path>` — 自定义 prompt 文件路径
- `--force` — 强制重新生成所有摘要（默认只处理未缓存的）

## 工作目录结构

```
/tmp/bz-YYYY-MM-DD/
├── events.jsonl          # 事件日志（append-only，管线状态的事实来源）
├── raw/                  # yt-dlp 原始输出（字幕文件 + *.info.json）
├── normalized/           # pysubs2 转换后的规范化 JSON
├── transcript/           # 最终可读的 Markdown 转录稿（含 frontmatter）
├── logs/                 # 各步骤的 stdout/stderr 日志
├── summary_items/        # 每个视频的 AI 摘要 JSON
├── summary_prompts/      # 生成的 prompt 存档
├── reports/              # 状态和失败报告（status.json / failed.jsonl 等）
└── summary.md            # 最终汇总的完整摘要文档
```

## 事件模型

管线使用 append-only JSONL 作为事件溯源存储。每个事件记录一个不可变的事实（`task_created` → `fetch_started` → `fetch_succeeded` → `transcript_ready` 等），状态通过重放事件推导。这使得：

- 支持断点续跑（失败后重跑不会重做已完成的任务）
- 支持查看历史进度
- 避免状态不一致

## 文件说明

| 文件 | 说明 |
|---|---|
| `run.nu` | 主流程脚本，包含所有子命令实现 |
| `run_test.nu` | 单元测试 |
| `fix_json.py` | Python 辅助工具，修复 AI 输出中未转义引号导致的 JSON 解析失败 |
