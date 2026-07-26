---
name: table2yml
role: atom
description: 把对比 table 落成扁平 YAML codeblock（选型 xxx.table.yml 用）
---

# table2yml

我要的不是YAML配置

而是把上面那个table以YAML格式给我 codeblock

格式类似



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


---

返回的 YAML code block需要注意以下事项：

- 注意这个 key 只有一层（不要嵌套多层），且 value 均为字符串；禁止空字符串 value；引号写法与上方示例一致即可
- 如果value有多行或者多项的话，那么需要做成多行字符串。该字符串的每行都以- 开头（注意- 后面需要空格）
- 以name为第一个key
- 如果有url和doc的话，在name后面都加上相应的url以及doc。如果没有就不写url和doc了。
- 除了name、url和doc（如果有的话），所有的key都需要中文（除非特别标识某个key需要英文）
