---
frontmatter:
  name: table2yml
  role: atom
  desc: 把 md 对比表格转扁平 YAML codeblock（用 miller，不用 AI 心算）
---

## what

**是什么：**

用 miller 把用户粘贴的 md 对比表格转成扁平 YAML list（`- name: <第一列值>`，其余列标题作 key）。

**不是：**

不是 AI 心算转换（会漂移/幻觉）
不是 json/csv 转换
不做多表拆分（一次一个表）

## constraint

### must

1. 第一列必须重命名为 `name`（`rename <第一列>,name`）
2. 值保持字符串，不手动加引号（miller 输出即合法 YAML）
3. 只在输出中标良 YAML codeblock（````yaml ````）

### must-not

1. 禁止 AI 手写 YAML（必须走 miller 命令）
2. 禁止嵌套 key（key 仅一层）

## workflow

### 落盘表格

1. 把用户消息里的 md 表格原样写入临时文件 `/tmp/t2yml.md`（含表头行）

### miller 转换

1. 用 `nix run nixpkgs#miller -- --m2y rename <第一列>,name /tmp/t2yml.md` 生成 YAML
2. 列名含特殊字符直接按原文（rename 逗号分隔 `<列>,name`）
3. 输出包裹在 ````yaml ```` codeblock

### 无表格处理

**gate:** 用户消息中没有 md 表格

1. 回复「请输入 Markdown 对比表格」并等待用户粘贴

## output

**format:** yaml

**few-shot:**

```markdown
```yaml
- name: Rod
  性能: "更优（解码按需）"
  内存消耗: "更低"
  默认浏览器管理: "自动下载管理"
  并发处理: "无死锁（goob基础）"
  协议支持: "DevTools"
  配置灵活性: "高（可替换WS库）"
  架构稳定性: "稳定（版本绑定）"
  依赖项: "极少"
  跨浏览器支持: "仅Chromium"
  最佳适用场景: "自动化/爬虫"

- name: Chromedp
  性能: "较低（全JSON解码）"
  内存消耗: "较高"
  默认浏览器管理: "依赖系统浏览器"
  并发处理: "高并发易死锁"
  协议支持: "DevTools"
  配置灵活性: "较低"
  架构稳定性: "版本冲突风险"
  依赖项: "较多（接口复杂）"
  跨浏览器支持: "仅Chromium"
  最佳适用场景: "简单Chrome操作"
```
```
