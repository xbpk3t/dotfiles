---
name: table2yml
role: atom
description: 把对比 table 落成扁平 YAML codeblock（选型 xxx.table.yml 用）
---

# table2yml

将上文对比表格转为扁平 YAML codeblock。格式如下：

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

输出规则：

1. key 仅一层（禁止嵌套），value 均为字符串，禁止空字符串。引号格式参考上方示例。
2. 多行/多项 value 用多行字符串，每行以 `- ` 开头（注意 `-` 后需空格）。
3. name 为第一个 key。
4. 如有 url/doc，紧随 name 之后；无则省略。
5. 除 name/url/doc 外，所有 key 使用中文（除非另有标注）。
