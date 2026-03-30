---
title: colmena-vs-deploy-rs
type: review
status: active
date: 2026-02-10
updated: 2026-02-10
slug: /2026/colmena-vs-deploy-rs
unlisted: false
tags:
  - nix
  - nixos
---

```markdown
有个关于nixos的问题

我之前使用colmena，现在使用 deploy-rs

为啥我感觉相同的配置，但是现在rebuild就是比之前慢很多呢？

这个正常吗？社区有人反馈这个issue吗？
```

colmena 如果rebuild失败了，会自动回滚到上一个 generation吗？

```markdown
如果失败发生在 switch/activation 阶段：Colmena 也没有类似 deploy-rs 的 “magic rollback（失败自动回滚）” 机制；这在 Colmena 里是被提过的需求而不是现有默认行为。

---

是的，我说的就是这个东西

为啥呢？我是从 colmena -> deploy-rs 的用户

感觉这个很好用
```

```markdown
明白了，是否二者机制不同，也是导致有时感觉 deploy-rs 在 copying阶段（还有其他阶段），比 colmena 要慢很多 的原因？

你搜搜社区的issue，看看是否有人反馈，再结合二者的机制聊聊
```
