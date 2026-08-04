---
name: strike
role: atom
description: 三振出局式深潜学习（主 agent 编排）：分组→起 sub-agent→收集 conclusion→export
trigger:
  - manual
---

# strike — 深潜学习编排（主 agent 视角）

**是什么：** 用户把浏览器里的技术资料按 topic 手动分组后，你负责**编排**：
为每个 topic 起一个独立 sub-agent，让用户进去深潜 3 轮，最后收集汇总。

**不是：** 不是你亲自做深潜分析（那是 sub-agent 的活）；不是读取浏览器 tab（opencli 实测不可行，用户手动分组）。

---

## 工作流

1. **用户输入**：按 topic 分组好的 URL/资料，交给你。
2. **对每个 topic**：
   - 初始化 counter：`nu <zzz_dir>/strike.nu reset <topic>`
   - 创建 sub-agent，prompt = 读 `references/wiki/strike-sub.md` 全文 + 注入 `topic` 名
   - 告诉用户：**"切到 sub-agent <topic> 交互（方向键下 + Enter）"**
3. **用户在各 sub-agent 里走 3 轮**，turn 3 时 sub-agent 自动回传 conclusion。
4. **收集**所有 topic 的 conclusion。
5. **全部完成后**：汇总成 digest + 提示 session export。

## 硬约束

1. **禁止**主 agent 亲自做深潜分析（资料内容的学习是 sub-agent 的职责）。
2. 每个 topic **一个 sub-agent**，一一对应，counter 文件 `/tmp/zzz/strike/<topic>.txt`。
3. sub-agent 创建时**必须**带上完整协议（strike-sub.md 内容），不要只给文件路径让它自己读。
4. 用户切换 sub-agent 靠 UI（方向键下 + Enter），主 agent 只负责初始化 counter + 创建 + 收集。
5. 收到 sub-agent 的 `[strike-sub] conclusion` 后立即登记，不丢弃。

## 输出契约

```text
## artifact
step: strike
status: ok
topics: <数量>
conclusions: <list 摘要>
```

## self-check（输出前必过）

| # | 项 | yes/no |
|---|-----|--------|
| 1 | 每个 topic 都 `strike.nu reset` 了？ | |
| 2 | 每个 sub-agent prompt 都包含完整 strike-sub.md？ | |
| 3 | 主 agent 没亲自做深潜分析？ | |
| 4 | 所有 conclusion 都收集了？ | |

## next

| 条件 | 建议 |
|------|------|
| 所有 sub-agent 完成后 | 汇总 digest + 提示 session export |
| 默认 | 停 |
