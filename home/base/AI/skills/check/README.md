# Check Skill

> Vendored from [qiyisoft001/verify-chain](https://gitee.com/qiyisoft001/verify-chain) (pin a7506f2).
> Local changes (LUC-284): all artifacts go under `/tmp/check/`, never workspace `.check-tmp`.

## 这是什么

一个使用 "角色对抗 + 上下文隔离 + 联网交叉验证" 机制来提升 IT 技术文章准确性的 AI 工具链。

写完一篇技术文章后，运行验证链：
1. AI 自动提取文章中的关键断言
2. 多个独立 AI 实例并行联网核查每个断言
3. 发现问题自动修复

## 快速开始

### 触发

```
/check
```
或直接说 "帮我验证这篇文章" / "核查一下文章内容有没有错误"。

### 模式

| 模式 | 命令 | 说明 |
|------|------|------|
| 全自动 | `/check` | 提取 → 核查 → 修复 → 报告，一气呵成 |
| 先审再改 | "先审再改，验证文章" | 核查完成后暂停，等你审核再决定修什么 |
| 只查不改 | "只查不改，验证文章" | 只输出核查报告，不修改文章 |
| 重点检查 | "重点检查命令参数，验证文章" | 将关注点传递给 Critic |

### 输出目录

所有中间物与终产物写入：

```
/tmp/check/YYYYMMDD-<slug>/
├── assertions.md              # Critic（可选落盘）
├── verification-results.md    # Verifier 汇总（可选落盘）
├── article-verified.md        # 修复后文章
└── verification-report.md     # 完整核查报告
```

- **不写**工作区 / 文章旁 / `.check-tmp`
- 同日同 slug **覆盖**该目录
- `/tmp` 重启可能清空，属预期

## 它不能做什么

- 验证你的个人观点或主观评价（"我认为 xxx 是最优方案" 这种）
- 验证纯原创理论（没有公开资料可对照）
- 替代专业领域专家的深度审稿
- 100% 消除所有错误（AI 本身也有局限）

## 文件结构

```
check/
├── SKILL.md              # 入口 + 流程编排 + 落盘规则
├── prompts/
│   ├── critic.md         # Critic 系统提示词
│   ├── verifier.md       # Verifier 系统提示词
│   └── repairer.md       # Repairer 系统提示词
└── README.md             # 本文件
```
