---
title: 远程开发具体实践review

---



注意远程开发跟异地组网（尤其是其优化）高度相关，为啥？

因为远程开发体验（在cost不变的情况下）有两个核心限制：网络latency和机器性能，本身也是EQC三角嘛。VPS有IPv4，所以会有更好的latency，但是机器性能不会太好。所以我们通常会选择本地机器，会有更好的机器性能，那么就需要自己去优化网络latency了，而异地组网就是目前最优方案。





接入方式（IDE/协议） + 运行载体（VM/容器/k8s） + 环境描述（DevContainer/nix）










```yaml
        - date: 2026-01-12
          des: |
            我之前尝试了 jetbrains 和 vscode 的远程开发。简单来说，jetbrains 的问题在于，一旦把这个 gateway关掉之后，连接就掉了，直接 goland client 也跟着掉线了现在这两个加起来之后，比之前本地直接作为 server 的内存开销还高

            之后我尝试直接使用本地的goland里内置的gateway打开这个remote 无法直接复用我本地的goland，而是会重新打开一个 thin client 此时我本地就会有3个进程： goland, gateway, goland thin client，内存占用分别是 3GB 670MB 1.8GB 体验很差。太TM变态了，有人说不是这样的，其实只需要后面的 gateway + thin client 就足够了，真的吗？这就是 jb相较于 vscode/zed 的最大区别，这个 thin client必须搭配gateway使用，否则压根用不了（“打不开工程也跑不了索引/代码分析/调试这些核心能力”）。

        - date: 2026-01-21
          des: |
            最近一直在玩远程开发，目前使用zed已经一周了，就相关过程做个记录。
            1、上条record并不准确，用Toolbox可以替代gateway，用来构建tunenl和拉起thin client。
            2、本地goland是必要的，否则没有本地IDE，本地项目无法启动。
            3、thin client带来一个问题，不能用alfred的CMD直接打开。

            两个附加问题：
            - GoLand/JetBrains Remote Dev 现在还有哪些硬伤？VS Code/Zed 远程是不是就没有这些问题？还是也有别的硬伤？
            - 三者核心架构/实现类似吗？vscode这套不也是“索引、分析、编译等重活都在远程机器上” 吗？跟jb这套有啥区别？能否找个恰当的类比，形象地帮我说明一下？

            JetBrains 的 Gateway/Toolbox 是“店长/调度”，Client 是“前厅服务员”，远端 backend 是“中央厨房”；你同时开本地 GoLand 等于又开了一家“本地完整店”，所以内存爆。VS Code 把“店长功能”藏在同一个客户端里；Zed 更轻但成熟度不同。真差异是“中央厨房（统一 IDE 内核）” vs “模块档口（LSP/扩展/适配器）”。

            从works到现象，正因此，所以jb这套对latency更敏感，导致体验很差，这是架构层面的问题，改不了，所以我放弃了jb

        # JetBrains 路线：中央厨房（完整 IDE 内核远端化）
        # - 优点：GoLand 级重构/inspections/导航一致性强，上限高。
        # - 代价：分体显性（Client + 入口）、链路长、资源重、对网络与会话更敏感。
        # VS Code / Zed 路线：模块档口（LSP/扩展/工具链远端化）
        # - 优点：客户端复用感强、切换自然、模块化灵活。
        # - 代价：体验一致性高度依赖生态（语言服务器/扩展/调试适配器质量），不同语言/组合差异更大。
        # Zed 属于更轻快的新选手，但成熟度/边缘场景确定性通常不如 VS Code。
```


注意 jb 和 vscode 想要配置 RD，还都需要配置对端（server端）的 nix

列出 commit-id

zed其实也需要，但是要简单很多




jb 和 vscode/zed 走了两条线路

抓手：怎么切分、怎么通信、谁提供寓意能力，以及 失败/性能的边界在哪里

thin:
