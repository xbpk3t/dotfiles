---
title: AI时代编程：从手写实现到抽象、编排与验证
type: review
date: 2026-03-26
updated: 2026-03-30
slug: /2026/AI-dev-in-the-LLM-era
unlisted: false
tags:
  - LLM
  - AI
  - coding
  - engineering
  - workflow
summary: 讨论 AI 时代编程范式的变化，以及程序员如何把重心从手写实现转向问题定义、上下文组织、验证闭环与能力提升。
---





为什么 CLI 反而成了 Agent 时代最自然的接口？
为什么传统 SaaS 的 API 思路正在失效？
Workflow vs Agent，产品的“确定性”和“无限组合”该如何取舍？
为什么你会不知不觉中消耗更多内容，甚至更多 token？
以及——未来的软件，是不是只剩下“原子能力 + AI 组合”？



https://x.com/fkysly/status/2038923902135779762

test code 是真正的核心代码，才是护城河（参考之前cf用几天时间复制了一套nextjs，就是因为其测试代码也开源了） -> AI时代，可以有助于我们提高代码质量



### 我目前的 skills 管理




:::tip


本文算是有一定，知道并熟练使用 MCP, skills, agent 等AI工具等常用功能

1. AI 为什么让“写代码”更容易了。
2. 但为什么同时又让“把事做对”更难了。
3. 真正的分水岭不在会不会用工具，而在于会不会定义问题、组织上下文、设计验证。
4. 所以 AI 时代程序员的核心能力，从“手写实现”转向“抽象 + 编排 + 验证 + 迭代”。
5. 最后再落到：怎么用 AI 提高效率，以及怎么用 AI 反过来提升自己的编程能力。

:::


## 基本认知



```markdown
  ## 1. AI 时代编程的真正变化是什么

  放在最前面，作为总论。
  可写：

  - “写代码”被压缩成了更便宜的环节
  - “定义任务”和“验收结果”变成更稀缺的能力
  - 程序员角色从 coder 变成 architect / reviewer / orchestrator

  ## 2. LLM 悖论：记得更多，却理解得更少

  这个你已经有素材了，建议单独成节。
  可写：

  - LLM 擅长局部补全，不天然擅长全局抽象
  - 人脑记忆差，反而逼自己做压缩、抽象、归纳
  - 所以 AI 很强，但缺少“自己停下来重构问题”的能力
  - 这解释了为什么 AI 常常“看见树木，看不见森林”

  ## 3. AI 编程为什么反而对人要求更高

  这个是全文核心节。
  可写：

  - 你要会判断需求真假边界
  - 你要会拆任务，而不是直接丢一句“帮我实现”
  - 你要会识别幻觉、伪完成、局部最优
  - 你要有足够基础，才能知道 AI 哪里在胡扯
  - AI 放大的是人的上限，也放大人的短板
```


LLM悖论：完美记忆+泛化能力差 -> 人类记忆力差是feat，而非bug -> 记不住，大脑进入抽象模式，“看到森林而非树木”

人类则是 记忆力差，泛化能力（抽象能力）强









## 怎么用AI工具来提高开发效率？



### 高效使用 AI 编程工具的工作流


```yaml
# FIXME: 逐项实践一下他这几条 [axtrur on X: "开个经验贴总结下使用claude code的一些小tips： 1. 【Plan First】: 任务开始之前的Plan很重要，除了提示词描述好任务细节外，可以结合task-master对PDR进行任务拆解，描述好优先级和依赖关系，然后让claude code基于.taskmaster/tasks/tasks.json的规划进行开发 2. 【Create Sub Task】:" / X](https://x.com/axtrur/status/1934135527206469994)
# 开个经验贴总结下使用claude code的一些小tips：
#  1. 【Plan First】: 任务开始之前的Plan很重要，除了提示词描述好任务细节外，可以结合task-master对PDR进行任务拆解，描述好优先级和依赖关系，然后让claude code基于.taskmaster/tasks/tasks.json的规划进行开发
#  2. 【Create Sub Task】: 对一些任务开始之前的方案调研或者可以分拆分拆任务然后合并的需求，可以显示的让claude开启sub Task进行Deep Research或者子任务拆解
#  3. 【Iterate UI with Pupeteer】：对于设计图还原，可以让Claude code使用puppeteer MCP进行网页浏览、网页截图从而反复迭代，保证跟UI设计稿的一致性。
#  4. 【Context Auto Compact】:  Claude Code的机制注定上下文消耗很快，当任务上下文特别长但是又不想clear的时候，可以执行/compact 手动对进行上下文压缩
#  5. 【MCP自举】：当有些功能不满足时，可以让Claude Code开发对应的MCP然后调用claude mcp add命令进行自注册
#  6. 【Stage Early, Stage Often】：为了代码的测试、验证、回滚，可以配合Git进行迭代、验证、提交
#  7. 【Git Worktrees】: 有群友提到可以使用Git Worktrees让claude在同个git工程下同时执行两个不同的任务（这个尚未验证）
```




---



[讲真，Ai编程对人的要求更高了 - 搞七捻三 - LINUX DO](https://linux.do/t/topic/1844995)


https://tonybai.com/2026/03/29/stop-mindless-ai-coding-we-are-heading-to-a-dead-end/





---







### SuperPowers 的使用

https://linux.do/t/topic/1836688

***https://x.com/xxx111god/status/2038093217782997144***

gstack 是啥？



https://github.com/NousResearch/hermes-agent
https://github.com/walkinglabs/awesome-harness-engineering

https://x.com/dotey/status/2027156511555027252


[想开一个 harness engineering 实践的长期帖子，大家一起分享实践经验 - 开发调优 - LINUX DO](https://linux.do/t/topic/1791588)


https://x.com/kasong2048/status/2038629427224137957

*https://x.com/YuLin807/status/2038930138562482278*


https://x.com/jarodise/status/2038427720473039222


https://linux.do/t/topic/1854004



https://x.com/FradSer/status/2038873041707717054



其实 [spec-kit](https://github.com/github/spec-kit)







### tricks

告诉 AI如何验证，而非哪里错了（输入、期望结果、实际输出）





```markdown
  ## 5. 不要告诉 AI 哪里错了，要告诉它如何证明自己是对的

  这节非常重要，值得单独展开。
  可写：

  - 错误反馈的低质量写法：“这不对，你再改改”
  - 高质量写法：输入、预期输出、实际输出、验证命令、失败日志
  - 把“挑错”升级成“定义验收标准”
  - 让 AI 跑测试、截图、lint、diff，而不是只改代码
  - “验证设计”是 AI 编程时代最关键的工程习惯
```



## 怎么真正用LLM编程工具来提升自己的编程水平？


### 用 LLM 提高效率，与用 LLM 提高能力，是两回事


LLM毫无疑问是很强大的工具，但是强大的工具，需要驾驭工具的人更加强大，才能真正用好。这是个很粗浅、不言自明的道理，不用多说。

其实 “用LLM提高效率”和“用LLM提高个人能力” 看起来是一码事，仔细一想是两码事，真正思考之后其实还是一码事。二者之间的差距在哪？在于复盘，更高效的复盘。

如果把我们每天工作替换为看书的话，按照 PQ4R 来说，我们可以理解为，在没有LLM时，我们每天只能读1-2本书，在有了LLM之后，我们的效率提高了3倍，每天都能读5本书左右。但是真正的问题在于，是否有这个 reflect, recite, review 的过程？


> “知道什么是好的，很重要，或者说，是最重要的 => 规范-sense”






### 怎么真正借 AI 提升编程水平


```markdown
  ## 7. 用 LLM 提高效率，与用 LLM 提高能力，是两回事

  这个建议作为后半篇转折。
  可写：

  - 提高效率：让 AI 替你做执行层工作
  - 提高能力：让 AI 暴露你的思维漏洞
  - 如果只是让 AI 代写，你会越来越依赖
  - 如果让 AI 参与审题、拆解、对拍、复盘，你会成长更快

  ## 8. 怎么真正借 AI 提升编程水平

  你已有这个 heading，但内容还空。
  建议重点写：

  - 让 AI 解释设计权衡，而不是只要答案
  - 让 AI 提供多个方案并比较 trade-off
  - 让 AI 给你写测试，再反向理解接口设计
  - 让 AI review 你的设计，而不是代替你设计
  - 做完之后让 AI 帮你复盘：哪里是需求问题，哪里是实现问题，哪里是验证问题

  ## 9. AI 编程时代，程序员最该强化的能力

  适合做总结节。
  可写：

  - 抽象能力
  - 任务拆解能力
  - 上下文组织能力
  - 验证与调试能力
  - 工程判断力
  - 对系统边界和风险的敏感度
```



## 总结
