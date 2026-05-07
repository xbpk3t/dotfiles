---
title: Taskfile 不是命令垃圾桶：一次迟来的清理与重建原则
date: 2026-04-30
isOriginal: true

---


:::tip[TLDR]

具体修改参考

[Comparing ad215771c147d9c1765bc771ff33a63e93c5a603...0ca57ee584e64c3365e08fb5f616490af07a8e67 · xbpk3t/dotfiles](https://github.com/xbpk3t/dotfiles/compare/ad215771c147d9c1765bc771ff33a63e93c5a603...0ca57ee584e64c3365e08fb5f616490af07a8e67)


---

花了很大精力，最终把这个taskfile重新做了缩减


<details>
<summary>减少了187个task</summary>


处理之前278个

```markdown
➜ task -t ./.taskfile/Taskfile.yml count                                          0s
devops   19
k8s      3
kernel   60
langs    17
mac      1
network  148
nix      10
works    20
```

处理后91个

```markdown
➜ task -t ./.taskfile/Taskfile.yml count
devops   19
k8s      3
kernel   4
langs    17
mac      1
network  28
nix      10
works    9
```

</details>


相比于之前，算是一个可用状态

经过这么一轮扩张再缩减，真正重要的、真正学到的东西是：

这个 dotfiles/.taskfile 不应该是各种 taskfile 的堆砌，而是

- 1、【能用 TUI 代替的，就直接用 TUI 管理】比如说 systemd, launchd, journalctl, docker, helm 之类的。优势在于：本身就
- 2、【分清楚Taskfile是项目级还是全局级】比如说 `Taskfile.gz.yml` 之类的这些，更应该直接放到 gozero 项目里，而非作为全局使用。同理的还有 `Taskfile.alfred.yml`。之前想要把所有日常用到的 Taskfile 都集中管理，方便维护。现在想来这个想法很蠢（压根不需要全局使用的东西，为啥要放到全局里呢？）***目前把这类文件直接放在 [taskfile/README.md](./docs/taskfile/README.md) 里维护了***
- 3、【知识记录与执行入口分离】这次 refactor 的一个隐性结论是：很多 taskfile 本质是知识备忘（如 nixos-anywhere 完整流程、defer 语法解释、helm-dashboard对比），但用 taskfile 做这事的维护成本太高。现在做法是：知识放代码 注释或独立文档，taskfile 只保留可执行入口。典型例子：nixos-anywhere 整个 taskfile 被注释化。
- 4、【可能并非所有cli都应该包装成Taskfile】SSH 从一整个 Taskfile（~40 行）收缩到 3 条 shell 命令，且论证了 set-permissions 在现代 ssh-keygen 下是多余的。这是值得在 TLDR强调的收缩粒度判断标准。


这个也算是 Taskfile 极简之道了吧

:::









## golang


## mac

### Taskfile.mac-cleanup.yml


### Taskfile.scratches.yml

直接移除掉了

b473ff590d0627bb6c081511ad0c98357c8c6182



### Taskfile.mac.yml -> launchd


:::tip

“对于 launchd，不需要 TUI，记住 launchctl print/bootout/kickstart 几条命令就行，相关 task 已移除。”

:::




```yaml
# MAYBE: [2026-04-20] 看看有什么操作 launchd 的 TUI，找了一下没找到，都是一些star<5，没人用的repo，之后再看吧。反正这玩意也没用过，所以注释掉
# 目前看了 launchk（我感觉这个东西功能其实很有限，更多只是一个 list launchd的功能，针对某个 launchd 的二次操作，几乎没有），lunchy 和 lunchy-go 都已经EOL了
# https://github.com/intellekthq/launchk

```


```markdown

我想了一下，其实对于 launchctl

并不需要一个TUI工具，其实最简单的是，记住几个核心cli，另外就是掌握高效搜索 service 的方法

是否如此？

---


1、那么有哪些核心cli?

2、怎么高效搜索 service?

```


[JeremieAlcaraz/launch-tui-macos: TUI to manage macOS LaunchAgents and LaunchDaemons](https://github.com/JeremieAlcaraz/launch-tui-macos)

[intellekthq/launchk: Rust/Cursive TUI for observing launchd agents and daemons](https://github.com/intellekthq/launchk)

[launchctl/launchd cheat sheet](https://gist.github.com/masklinn/a532dfe55bdeab3d60ab8e46ccc38a68)




```yaml
launchctl_core:
  # 查看当前 GUI 用户 domain 下所有已加载的 LaunchAgents
  print_gui_domain: "launchctl print gui/$(id -u)"

  # 查看 system domain 下所有已加载的 LaunchDaemons
  print_system_domain: "sudo launchctl print system"

  # 查看某个用户态 service 的完整状态
  print_gui_service: "launchctl print gui/$(id -u)/com.example.service"

  # 查看某个系统态 daemon 的完整状态
  print_system_service: "sudo launchctl print system/com.example.service"

  # 加载用户态 LaunchAgent
  bootstrap_gui: "launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.example.service.plist"

  # 加载系统态 LaunchDaemon
  bootstrap_system: "sudo launchctl bootstrap system /Library/LaunchDaemons/com.example.service.plist"

  # 卸载用户态 service
  bootout_gui: "launchctl bootout gui/$(id -u)/com.example.service"

  # 卸载系统态 service
  bootout_system: "sudo launchctl bootout system/com.example.service"

  # 重启用户态 service，-k 表示先 kill 再启动
  restart_gui: "launchctl kickstart -k gui/$(id -u)/com.example.service"

  # 重启系统态 service，-k 表示先 kill 再启动
  restart_system: "sudo launchctl kickstart -k system/com.example.service"

  # 禁用用户态 service，状态会持久化
  disable_gui: "launchctl disable gui/$(id -u)/com.example.service"

  # 启用用户态 service
  enable_gui: "launchctl enable gui/$(id -u)/com.example.service"

  # 禁用系统态 service，状态会持久化
  disable_system: "sudo launchctl disable system/com.example.service"

  # 启用系统态 service
  enable_system: "sudo launchctl enable system/com.example.service"

  # 查看用户态 service 最近为什么被启动
  blame_gui: "launchctl blame gui/$(id -u)/com.example.service"

  # 查看系统态 service 最近为什么被启动
  blame_system: "sudo launchctl blame system/com.example.service"

  # 查看用户态 disabled services
  print_disabled_gui: "launchctl print-disabled gui/$(id -u)"

  # 查看系统态 disabled services
  print_disabled_system: "sudo launchctl print-disabled system"

  # 给用户态 service 发信号
  kill_gui: "launchctl kill SIGTERM gui/$(id -u)/com.example.service"

  # 给系统态 service 发信号
  kill_system: "sudo launchctl kill SIGTERM system/com.example.service"

  # legacy 快速列表，适合粗搜 PID / exit status / label
  list_gui_legacy: "launchctl list"

  # legacy 快速列表，适合粗搜系统 daemon
  list_system_legacy: "sudo launchctl list"

  # 查看某个 PID 对应的 launchd execution context
  procinfo: "sudo launchctl procinfo <pid>"
```



```yaml
  #   选中 target 之后，后续操作仍然使用原生 launchctl 命令手动执行：
  #
  #     launchctl print <target>
  #     launchctl kickstart -k <target>
  #     launchctl bootout <target>
  #     launchctl disable <target>
  #     launchctl enable <target>
```









## devops


### Taskfile.git.yml

```yaml
  #- git remote rm origin && git remote add origin <url> # git 怎么修改远程仓库地址
  modify-origin:
    desc: 修改远程仓库地址
    summary: "task -g modify-origin"
    dir: '{{.USER_WORKING_DIR}}'
    cmds:
      - git remote rm origin
      - git remote add origin {{.CLI_ARGS}}


# fork 后如何同步源的最新代码：我fork出来的分支，怎么同步后来父分支的更新？ # [Syncing a fork - GitHub Docs](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork) git remote add <upstream> && git fetch <upstream> && git checkout main && git merge <upstream>/master


  # 怎么合并多个 commit? rebase、merge、cherry pick都可以合并多个 commit，有啥区别? Why we'd better use merge?***" # rebase 操作和 cherry-pick 操作都会修改 commit-id，导致无法追溯问题。所以通常禁止使用，只允许 merge 操作公共分支（merge将两个分支上的所有提交记录合并成一个新的提交记录，并且保留原来的提交记录。这个操作不会修改提交记录的 SHA 值），方便 debug。
```


添加了 git-extras 和 git-sync 这两个服务







### Taskfile.linters.yml

[feat(taskfile): 移除 Taskfile.linters.yml. 之后做成各repo里fetch模式（而非从dotfile… · xbpk3t/dotfiles@de49db4](https://github.com/xbpk3t/dotfiles/commit/de49db414dd11b8d1d5b7f63961d597cfefd334b)



#### 之前的设计

最初方案是「dotfiles 作为中心源，向项目侧分发」：扫描项目已有 linter 文件，与 dotfiles 做交集，然后逐个处理差异。
冲突时走交互分支（覆盖 / 查看差异 / 跳过），目标是同时兼顾统一性和项目特例。

#### 出现的问题

实际使用里主要有三个问题：
1. 入口不稳定（include 注释、文件命名不一致），导致任务存在但不常被触发。
2. 交互步骤多，批量维护成本高，流程容易中断。
3. 语义不够纯粹：看起来是“统一覆盖”，实际上允许“跳过”，且默认只处理交集，不是严格镜像。

#### 为什么从分发逻辑变成 fetch 逻辑

核心考虑是把风险和决策下沉到 repo 侧：
1. 各 repo 主动拉取，升级节奏可控，不会一次改动影响全部项目。
2. 每次同步都在目标 repo 内形成可审计变更，回滚更直接。
3. 更符合现实场景：不同 repo 需要不同 linter 文件集合。

#### 目前的设计

当前改为最小声明式 fetch 模型：只保留 `repo / path / files` 三个元数据。
任务职责保持单一：
1. `sync` 负责按声明拉取并覆盖。
2. `check` 负责对比远端与本地是否漂移（不写入）。
   这样在保持统一性的同时，避免把流程做成重模板系统。

#### 边界与不做的事

当前刻意不做以下内容：
1. 不做多层模板继承或复杂生成器。
2. 不做交互式冲突处理（避免流程再次变重）。
3. 不默认做“全量镜像删除”（即不自动删除 repo 中未声明文件），后续如需要可单独加 strict 模式。






### Taskfile.caddy.yml

:::tip

现在对于 caddy 的普遍用法，应该都是直接通过 container 去启动，很少有人直接把caddy作为process在宿主机直接使用。这些命令其实都没啥用了。

更准确的说法是：

caddy 的命令分清用法，validate/adapt/fmt/list-modules 保留用于配置维护，生命周期全交给容器或 systemd；相关 task 只保留配置检查入口。

:::



```markdown
可以。下面按**一问一答**分组总结。

## 1. 你问：这些 Caddy 命令现在还有没有用？宿主机直接跑 process 是否已经过时？

**你的问题总结**
你贴了一份围绕 `caddy run/start/stop/reload/validate/adapt/file-server/reverse-proxy` 等命令的配置，怀疑它们整体已经没什么价值了。你的核心判断是：现在更普遍的是在 container 里启动 Caddy，而不是在宿主机上直接把 Caddy 当进程来管理，所以这些命令可能整体都偏过时。

**我的回答总结**
我的判断是：

* 你的直觉**有一半对**。
* 过时的不是 **Caddy CLI 本身**，而是“**把 Caddy 自己当作进程管理入口**”这套思路。
* 在现代部署里，进程生命周期更常交给：

  * container / compose / k8s
  * 或宿主机上的 systemd
* 但这不代表 `caddy` 命令没用。真正仍有价值的，是：

  * `validate`
  * `adapt`
  * `hash-password`
  * `list-modules`
  * 某些场景下的 `run` / `reload`
* 最边缘化的是：

  * `start`
  * `stop`
* `file-server` / `reverse-proxy` 更像快捷命令，适合 demo、临时服务、本地调试，不太像长期团队运维入口。

---

## 2. 你问：container 里能不能直接调用 `caddy`？是不是其实只剩 `validate / adapt / list-modules` 这三个有用？

**你的问题总结**
你进一步追问：如果 Caddy 是跑在 container 里，还能不能直接执行 `caddy` 命令？并且你初步判断，真正值得保留的命令其实只剩：

* `validate`
* `adapt`
* `list-modules`

**我的回答总结**
我的判断是：

* **能**。如果容器里就是官方 Caddy 镜像，通常可以直接执行 `caddy` 命令。
* 更准确的说法不是“没人用 Caddy CLI 了”，而是：

  * **仍然用 Caddy CLI**
  * 只是**不再依赖它管理生命周期**
* 所以你提到的三类命令在容器时代仍然成立，而且很合理：

  * `validate`：检查配置是否有效
  * `adapt`：看 Caddyfile 最终被翻译成什么 JSON
  * `list-modules`：确认镜像里有哪些模块
* 我另外补充建议：

  * `fmt` 也值得保留
* 因此整体方向变成：

  * **生命周期管理**交给 container / compose / systemd
  * **维护与诊断**交给 `caddy validate / adapt / fmt / list-modules`

---

## 3. 你问：`adapt` 到底有什么用？为什么要把 Caddyfile 转成 JSON？`validate` 有没有第三方 linter，pre-commit 怎么做？

**你的问题总结**
你主要问了两件事：

1. `adapt` 的真实价值到底是什么，为什么要从 Caddyfile 转 JSON
2. `caddy validate` 有没有配套第三方 linter，特别是如果想在 pre-commit 里做检查，该怎么设计

**我的回答总结**
我给出的核心判断是：

### 关于 `adapt`

* `adapt` 不是为了要求你把项目迁移到 JSON
* 它更像一个**调试和解释工具**
* 核心价值是：把 `Caddyfile` 翻译成 Caddy 实际吃的原生配置，让你看到：

  * import/snippet 展开后长什么样
  * matcher / route / handle 最终怎么组织
  * Caddy 实际理解的配置是什么
* 所以它更适合：

  * 排错
  * 理解配置展开结果
  * 自动化场景下做调试
* 不是日常每次都必须跑的命令

### 关于 `validate`

* `validate` 是更强的有效性检查
* 它不只是看“能不能适配”，还会更接近真实启动前的模块加载 / provisioning 检查

### 关于 linter / pre-commit

* 我没有看到一个“官方推荐、社区主流、成熟稳定”的独立第三方 Caddyfile linter
* 最稳妥的方案就是直接把官方 CLI 当 lint pipeline：

  * `caddy fmt --diff`
  * `caddy validate --config Caddyfile`
* `adapt --validate` 可作为辅助诊断，但不一定要放主链路
* 所以 pre-commit 最推荐的组合是：

  * **格式检查**：`fmt --diff`
  * **语义检查**：`validate`

---

## 4. 你问：这两个 hook 能不能合成一个？以后其他 Caddy 相关检查也能并进去吗？

**你的问题总结**
你贴了两个 pre-commit hook：

* 一个做 `fmt`
* 一个做 `validate`

你希望把它们收敛成一个 hook，并且考虑以后继续往里面追加其他 Caddy 相关检查。

**我的回答总结**
我的回答是：

* **可以，而且很适合合成一个**
* 最佳实践不是把一长串命令直接塞进 `entry`，而是：

  * 用一个脚本
  * 或统一走 Taskfile
* 这样后续扩展性更好，比如以后加：

  * `adapt`
  * container 版本执行
  * 多个 Caddyfile
  * envfile

我当时给了三种组织方式：

### 方式 A：最推荐

* pre-commit 调一个脚本，比如：

  * `./scripts/pre-commit/caddy-check.sh`

### 方式 B：可以先这么做

* inline 一个 `bash -c`，例如：

  * `caddy fmt --diff Caddyfile && caddy validate --config Caddyfile`

### 方式 C：如果你已经在用 Taskfile

* pre-commit 只调用：

  * `task caddy:check`
* 具体细分成：

  * `caddy:fmt`
  * `caddy:validate`
  * `caddy:check`

我还特别提醒了一点：

* `list-modules` **不适合**放进 pre-commit 的阻塞检查
* 因为它更像环境信息，不是配置正确性检查

---

## 5. 你问：那我就直接在 `entry` 里写 `caddy fmt --diff Caddyfile && caddy validate --config Caddyfile`，这样行不行？

**你的问题总结**
你最后想确认的是：
既然想合并成一个 hook，那是不是可以直接在 pre-commit 的 `entry` 里裸写：

**我的回答总结**
我的回答是：

* **不能裸写**
* 因为 pre-commit 的 `entry` 默认不是 shell 上下文
* `&&` 这类 shell 语法只有在你显式通过：

    * `bash -c`
    * 或 `sh -c`
      才能生效

所以正确写法应该是：

entry: bash -euo pipefail -c 'caddy fmt --diff Caddyfile && caddy validate --config Caddyfile'

另外我还补充了一个实现细节上的建议：

* `language: system` 可以工作
* 但更稳妥的现代写法是：

    * `language: unsupported`

---

# 最后，基于我们讨论的结论

我把最终结论收敛成几条：

## 一、对 Caddy 命令的总体判断

**不是“Caddy CLI 没用了”，而是“Caddy CLI 不再适合作为主要进程管理层”。**

换句话说：

* **有用的**：维护、检查、调试类命令
* **弱化的**：直接管生命周期的命令

## 二、哪些命令值得保留

你这个场景里，真正值得保留的核心命令是：

* `caddy fmt`
* `caddy validate`
* `caddy adapt`
* `caddy list-modules`（但不放 pre-commit）

其中：

* **最常用**：`fmt`、`validate`
* **调试辅助**：`adapt`
* **环境排查**：`list-modules`

## 三、哪些命令可以不再作为主要 Task 抽象

这些不必再作为你主要维护入口：

* `start`
* `stop`
* `run`
* `reload`
* `reverse-proxy`
* `file-server`

不是说绝对没用，而是：

* 生命周期应该交给 container / compose / systemd
* 快捷服务命令更适合临时场景，而不是长期项目维护接口

## 四、`adapt` 的定位

`adapt` 的定位应该明确为：

**“调试 Caddyfile 最终展开结果的工具”**，不是“日常必跑的部署动作”。

所以它适合：

* 查配置解释结果
* 看 import / snippet 展开
* 自动化调试

但不一定放进每次提交的 pre-commit 主链路。

## 五、pre-commit 的最佳实践

最合适的 pre-commit 主检查是：

1. `caddy fmt --diff Caddyfile`
2. `caddy validate --config Caddyfile`

如果要合成一个 hook，可以，推荐写成：

也就是：

* **可以合成一个 hook**
* **不能裸写 `&&`**
* **必须通过 shell 执行**

## 六、最终建议

如果让我替你给这个问题下最终判断，我会这样说：

**你的整体方向是对的：把 Caddy 相关任务收缩成“配置维护/检查”而不是“进程管理”，这是现代化且合理的。**

最实用的最小集合就是：

* `fmt`
* `validate`
* `adapt`（可选但推荐保留）
* `list-modules`（保留但不进 pre-commit）

而 pre-commit 就用一个合并 hook 跑：

* `fmt --diff`
* `validate`

这就是当前最干净、最稳、最符合你这套讨论结论的方案。

```




## k8s


[refactor(taskfile/k8s): 精简 Docker 任务并清理冗余 k8s 子 Taskfile · xbpk3t/dotfiles@20ffa14](https://github.com/xbpk3t/dotfiles/commit/20ffa144d0e3767502b2c4d91eae9811b74ae1d7)


直接移除掉

- Taskfile.dc.yml
- Taskfile.etcd.yml
- Taskfile.helm.yml
- Taskfile.k8s.yml
- Taskfile.podman.yml



### Taskfile.docker.yml



/Users/luck/Desktop/dotfiles/.taskfile/k8s/Taskfile.dc.yml

其实是之前搭配 `.cntr/golang` 使用的，里面大量针对性（并不通用）的task


```yaml
  dc-config:
    desc: 验证并查看 compose 配置
    summary: "task -g dc-config"
    cmds:
      - "{{.COMPOSE_CMD}} config"
    vars:
      COMPOSE_CMD: '{{.COMPOSE_CMD | default "podman-compose"}}'



  clean:
    desc: 清理所有容器、网络和卷
    summary: "task -g clean"
    cmds:
      - "{{.COMPOSE_CMD}} down -v --remove-orphans"
      - "{{.COMPOSE_CMD}} system prune -f"
    vars:
      COMPOSE_CMD: '{{.COMPOSE_CMD | default "podman-compose"}}'


```



```markdown
profiles可以理解为分组的概念，对吗？但是其实相当于tag，对吗？

那 compose是否有真正 一对一的类似概念？
---



对，**你可以把 `profiles` 理解成“分组”**，但从语义上说，**它更像“标签 / 开关条件”**，不是一个真正的一等“组对象”。原因是 Compose 官方定义里，`profiles` 是写在 **service 上的一个属性**，而且 **一个 service 可以属于一个或多个 profile**；没有 `profiles` 的 service 会默认启用。这个特征非常像 tag，而不像“一个 service 只能归属一个 group”的严格分组。([Docker Documentation][1])

更准确一点说，`profiles` 的作用是：**按场景选择性激活 services**。官方文档的表述就是“for different environments or use cases by selectively activating services”。所以它本质上不是在定义一个独立的“组”，而是在给 service 打一个或多个可激活的标记。([Docker Documentation][1])

你问“Compose 是否有真正一对一的类似概念”，结论是：**没有一个内置、独立、first-class 的 services 分组对象**。Compose 的一等模型核心还是 `services`、`networks`、`volumes` 等顶层元素；`profiles` 只是 service 上的筛选属性，而且官方还特别说明了：**除 services 外，其他顶层元素并不受 profiles 影响，始终处于活动状态**。这也说明 `profiles` 不是“把整套资源编成一个组”的机制。([Docker Documentation][2])

所以如果你想找“更像真正分组”的东西，Compose 里通常只有这几个近似物，但都不完全等价：

* **`service` 本身**：这是最小的一等单元，但它不是组。([Docker Documentation][3])
* **`project`**：也就是一整个 Compose 应用，`docker compose` 命令本身就是围绕 project 运行的；这更像“整套应用”的边界，不是组内子分组。([Docker Documentation][4])
* **多个 Compose 文件 `-f` 合并**：这是官方明确支持的，后面的文件会 override / add 到前面的配置上。这个更接近“模块化拆分”或“子栈组合”，比 `profiles` 更像真正的结构化组织方式，但它也不是“service 只能属于一个组”的一对一分组机制。([Docker Documentation][4])

所以你可以这样记：

* **`profiles` = tag / label / activation switch**
* **不是**严格意义上的 group
* **Compose 没有内置的一对一 service grouping 概念**

如果你想要“一个服务只能属于一个明确组”的那种感觉，Compose 里通常只能靠约定实现，比如：

* 约定每个 service 只写一个 profile
* 或者把不同组拆成不同 compose 文件，再用 `-f` 组合
* 或者用命名规范来表达分层

但这些都是**工程约定**，不是 Compose 在语义上强制提供的“真正分组”。([Docker Documentation][4])

拿你前面的例子来说，`dev`、`db`、`cache`、`monitor` 这些如果只是拿来开关一批服务，那它们更像“标签化场景入口”；如果你真正想表达“模块边界”，很多时候 **拆成多个 compose 文件** 反而更清晰。([Docker Documentation][4])

一个实用判断标准：

* **想做“可选启停”**：用 `profiles`
* **想做“结构化拆分 / 模块化维护”**：优先考虑多个 compose 文件
* **想做“严格一对一分组”**：Compose 没原生概念，只能靠约定

你要的话，我可以接着把 **“profiles vs 多 compose 文件”** 给你做一个很短的对照。

[1]: https://docs.docker.com/compose/how-tos/profiles/?utm_source=chatgpt.com "Use service profiles | Docker Docs"
[2]: https://docs.docker.com/reference/compose-file/?utm_source=chatgpt.com "Compose file reference | Docker Docs"
[3]: https://docs.docker.com/reference/compose-file/services/?utm_source=chatgpt.com "Services | Docker Docs"
[4]: https://docs.docker.com/reference/cli/docker/compose/?utm_source=chatgpt.com "docker compose | Docker Docs"

```



#### 相关操作

本轮针对 `/Users/luck/Desktop/dotfiles/.taskfile/k8s` 的调整，目标是把高频、低风险操作收敛到 `lazydocker`，把高风险或流程型任务继续留在 Taskfile。

- 管理入口收敛方向：
    - `Taskfile.dc.yml` 的大部分日常 Compose 操作，优先通过 `lazydocker` 原生能力 + `commandTemplates` 管理。
    - `Taskfile.docker.yml` 从“杂项工具箱”收敛为“复杂/高风险操作集合”。

- 已迁移到 `home/base/core/lazydocker.nix` 的 custom commands：
    - `inspect-ip`
    - `exit-code`
    - `image-history`
    - `analyze`
    - `verify`
    - `ctop`
    - `check-mem`（简化为 `docker stats --no-stream` 口径）
    - `check-cpu`（简化为 `docker stats --no-stream` 口径）

- 继续保留在 `Taskfile.docker.yml` 的任务类型：
    - 清理类：`system-clean`、`image-clean`、`log-clean`
    - 备份类：`image-backup`
    - 特权/环境依赖类：`capture`
    - 原因：这些命令副作用更大、依赖权限或环境前提，更适合通过 Taskfile 显式执行与审计。







#### check-cpu


```yaml
# 容器CPU利用率计算任务
# [如何正确获取容器的CPU利用率？ - 开发内功修炼@张彦飞 - 分享我的技术日常思考，和大伙儿一起共同成长！](https://kfngxl.cn/index.php/archives/642/) 这个问题有两个解决思路。思路之一是使用 lxcfs，将容器中的 /proc/stat 替换掉。这样 top 等命令就不再显示的是宿主机的 cpu 利用率了，而是容器的。思路之二是直接使用 cgroup 提供的伪文件来进行统计，这些伪文件一般位于 /sys/fs/cgroup/... 路径。kubelet 中集成的 cadvisor 就是采用上述方案来上报容器 cpu 利用率的打点信息的。
# 容器 cpu 使用率的指标项为什么比物理机上少了 nice/irq/softirq？ # 这个问题的根本原因是容器 cpu 利用率的指标项 user、system 和宿主机的同名指标项根本就不是一个东西。容器将所有用户态时间都记录到了 user 指标项，系统态时间都记录到了 system。容器中的 user 指标：在指标含义上等同于宿主机的 user + nice 容器中的 system 指标：在指标含义上等同于宿主机的 system + irq + softirq
```






• 不一致，思路是降级过的。

你原 check-cpu 的思路是：

- 直接读 cgroup CPU 累计时间（cpuacct.usage）
- 自己做两次采样和公式换算
- 追求“指标来源和计算过程可解释”

我现在放到 lazydocker 的 check-cpu 是：

- 用 docker stats --no-stream 直接拿 Docker 计算后的 CPUPerc
- 不自己采样、不自己算公式
- 追求“简单、通用、低维护”

所以关系是：

- 指标语义大体同类（都在看容器 CPU 使用）
- 计算路径不同（你的是显式 cgroup 采样，新的依赖 Docker 内部实现）

你如果要“严格延续原思路”，就得在 custom command 里保留采样脚本；但那会明显变复
杂、可移植性也更差。当前版本是你要求的“尽量简单”取舍。







```markdown
**Taskfile 没有 `postcmds` 这个字段。**

在官方文档和 schema 中，根本不存在 `postcmds`（或 `post-cmds`）这个配置项。早期的一些用户 Taskfile 示例里偶尔出现过 `post cmds:`，但那不是标准功能，只是社区自己写的自定义逻辑或旧版本的非官方尝试，现在已经不推荐也不支持了。

### 正确实现「任务结束后执行命令」的方式是 **`defer`**

`defer` 专门用来做 **cleanup / post-action**，它的关键特点是：

- **无论任务成功还是失败**，`defer` 里的命令/任务都会执行（类似 `finally` 块）。
- 可以放在 `cmds` 列表里，写成：
  ```yaml
  tasks:
    mytask:
      cmds:
        - echo "开始干活..."
        - ./do-something.sh
        - defer: echo "无论成功失败，都会执行这个清理"
        - defer: rm -f /tmp/tempfile
        # 也可以 defer 一个子任务
        - defer:
            task: cleanup
            vars: { MODE: full }

**和普通最后一条命令的区别**：
- 如果直接把清理命令写在 `cmds` 最后一条：
    - 前面命令失败时，后面的就不会执行。
- 用 `defer`：
    - 即使前面失败，defer 仍然会跑（非常适合清理临时文件、停止服务、回滚等）。

### 额外小贴士（defer 里能用的）

- 在 `defer` 中可以使用特殊变量 `{{.EXIT_CODE}}`（只有失败时才有值，非 0）。
  示例：
  ```yaml
  deploy:
    cmds:
      - ./deploy.sh
      - defer: |
          {{if .EXIT_CODE}}
          echo "部署失败，退出码 {{.EXIT_CODE}}，执行回滚..."
          ./rollback.sh
          {{end}}

如果你只是想「成功了才执行 post 操作」，那就不要用 `defer`，直接把命令写在最后面就行（或者用 `if:` 条件控制）。

总结：
- **没有 `postcmds`** → 别用了
- **用 `defer`** → 就是 Taskfile 官方提供的「后置/清理」机制

有具体想实现的场景（比如清理临时文件、总是运行某个通知等），可以把你的 Taskfile 片段贴出来，我帮你改成正确的 `defer` 写法。
```







***helfile 之于 helm，正如 compose 之于 docker***

都是在底层命令之上，再加了一层声明式编排能力

那么 chart-releaser 就相当于 Docker Registry (比如 Docker Hub)

它不负责管理集群里的应用（那是 Helm/Helmfile 的活），它只负责**“发布”**：把你的源码变成一个个带版本的压缩包，并生成一个让 Helm 能识别的“目录索引”（index.yaml）。



```markdown
如果你已经理解了 **"Helmfile 之于 Helm，就像 Compose 之于 Docker"**，那么我们可以顺着这个逻辑给 [chart-releaser](https://github.com/helm/chart-releaser) 定位。

### 1. 深度类比：它是谁？

在容器生态中，这个位置最贴切的类比是 **Docker Hub 的自动构建流水线** 或者 **私有镜像仓库的 Push 动作**。

* **Docker:** 负责打包镜像。
* **Docker Registry (如 Docker Hub):** 负责存储和分发镜像。
* **chart-releaser:** 它的作用就是**把 GitHub 变成你的 "Docker Hub"（Helm Chart 托管仓库）**。

它不负责管理集群里的应用（那是 Helm/Helmfile 的活），它只负责**“发布”**：把你的源码变成一个个带版本的压缩包，并生成一个让 Helm 能识别的“目录索引”（`index.yaml`）。

---

### 2. 决策评估：你是否需要它？

请根据以下 5 个场景进行自我评估，如果有 3 条以上符合，你就需要它：

#### **A. 基础设施成本：你想白嫖还是付费？**
* **需要：** 你不想维护 Harbor、Nexus 或付费使用云厂商的容器镜像仓库（它们通常都能存 Helm Chart，但要钱）。
* **情况：** 你希望利用 GitHub 免费的 **Releases** 存包，利用 **GitHub Pages** 存储索引文件。

#### **B. 协作对象：你的 Chart 是给谁用的？**
* **需要：** 你的 Chart 是**开源项目**，或者需要**跨团队/跨组织**共享。
* **情况：** 你需要一个公共的 HTTPS URL（如 `https://my-org.github.io/charts`），让别人一行 `helm repo add` 就能用，而不是让别人去拉你的 Git 源码。

#### **C. 发布频率与自动化程度**
* **需要：** 你希望每次在 GitHub 提个 Tag 或 PR，版本就自动更新。
* **情况：** 你厌倦了手动运行 `helm package` 然后手工修改 `index.yaml` 再上传。这个工具配合 [chart-releaser-action](https://github.com/helm/chart-releaser-action) 可以全自动完成这一切。

#### **D. 版本管理规范性**
* **需要：** 你需要严格的版本追溯。
* **情况：** GitHub Releases 会清晰地展示每个版本的发布时间、Changelog 和对应的 `.tgz` 包。如果你的团队对“哪个版本改了啥”有强需求，这比单纯看 Git Commit 记录要直观得多。

#### **E. 网络环境约束**
* **不需要（反例）：** 如果你的 Kubernetes 集群在**内网/离线环境**，且无法访问 GitHub。
* **情况：** 这时你应该用 Harbor 或自建仓库，`chart-releaser` 对你几乎没用，因为它强依赖 GitHub 的生态（Releases/Pages）。

---

### 3. 应用场景总结 (Decision Matrix)

| 场景 | 是否推荐使用 | 原因 |
| :--- | :--- | :--- |
| **开源项目发布** | **强烈推荐** | 行业标准做法，零成本实现高可用托管。 |
| **公司内部私有库** | **中等推荐** | 只要公司允许使用 GitHub Private Repo，这是最省事的方案。 |
| **本地开发测试** | **不推荐** | 直接 `helm install ./my-chart` 即可，没必要发布。 |
| **离线/内网环境** | **完全不推荐** | 工具核心逻辑是基于 GitHub API 的。 |

### 一句话建议：
如果你打算在 GitHub 上维护一个**长期更新**、需要**给别人（或自己的流水线）安装**、且**不想掏钱买仓库服务**的 Helm 项目，**闭眼选它就对了**。

你现在的评估结论是？
```







```markdown
你的直觉非常敏锐。在工程实践中，一旦引入了 **Helmfile**，你确实会发现自己几乎不再直接调用 `helm` 命令了。这类似于有了 **Docker Compose** 之后，你很少会去手动敲一长串 `docker run` 参数一样。

这种现象在技术演进中很常见：**底层工具提供能力，上层工具负责编排。**

以下是基于 [Helmfile 官方设计理念](https://github.com/helmfile/helmfile) 整理的两者关系及地位变化：

| | **维度** | **直接使用 Helm** | **通过 Helmfile 控制** | **地位变化** |
| ----- | ----- | ----- | ----- | ----- |
| 1 | **操作级别** | 战术级（安装单个 App） | 战略级（部署整个环境） | Helm 降级为“执行引擎” |
| 2 | **配置方式** | 命令行参数（-f, --set） | 声明式配置文件（YAML） | Helmfile 成为“真相来源” |
| 3 | **重复性** | 差（依赖 Shell 历史记录） | 极强（Git 管理配置） | Helmfile 实现了版本化 |
| 4 | **环境隔离** | 手动切换 Context | 脚本化切换 Environment | Helmfile 封装了复杂度 |
| 5 | **学习曲线** | 必须掌握的基础 | 进阶必经之路 | Helm 是基石，不可或缺 |

---

### 为什么 Helm 的意义并没有“下降”，而是“退居幕后”？

虽然你不再直接点火（敲 helm 命令），但火炉（Helm）依然是核心，原因如下：

* **调试（Debugging）依然靠 Helm**：当 Helmfile 报错时，你往往需要通过 `helm ls` 或 `helm get manifest` 来检查集群里到底发生了什么。Helmfile 擅长“写”，而 Helm 在“看”和“查”方面依然是第一手工具。
* **开发 Chart 的标准**：当你编写自己的应用包时，你是在写 **Helm Chart**。Helm 定义了打包、模板化和版本号的规范。没有 Helm 的这些规范，Helmfile 就像是没有砖块的建筑图纸。
* **插件生态依赖**：正如你提到的 `helm-diff`，这些强大的功能插件是挂载在 Helm 名下的。Helmfile 只是巧妙地调用了它们。

### 现在的典型工作流
1.  **开发阶段**：编写 `Chart.yaml` 和模板，用 `helm lint` 检查。
2.  **集成阶段**：编写 `helmfile.yaml`，定义生产、测试环境的不同变量。
3.  **部署阶段**：只执行 `helmfile apply`，让它去指挥 Helm 完成剩下的脏活累活。

> **比喻**：Helm 是一支**画笔**，Helmfile 是一位**画家**。画家虽然拿着画笔，但如果你想通过程序化、规模化地生产作品，你会更多地去跟“画家”沟通（修改配置），而不是去研究怎么握那根“笔”。

你现在是否正在考虑把现有的手动 Helm 命令转换成 `helmfile.yaml`？我可以帮你把一段复杂的 Helm 安装命令转换成声明式的 Helmfile 配置。
```




---


***选择使用 helm-dashboard***


```markdown
综合判断：**是的，`helm-dashboard` 比 `helm-tui` 更像我们前面讨论里“更好的 Helm 管理工具”**。但更准确地说，它不是“更好的 TUI”，而是**更好的 Helm 专用 UI / Console**。([GitHub][1])

为什么我会这么改判：

`helm-dashboard` 现在体量和成熟度明显更高：GitHub 上大约 **5.7k stars**，最近版本是 **v2.1.1（2026-03-27）**；而 `helm-tui` 大约 **140 stars**，最近版本是 **v0.6.0（2026-04-11）**。前者 README 明确列出能看已安装 chart、revision history、past revision 的 manifest diff、关联的 K8s 资源、做 rollback / upgrade、多集群切换，还能本地跑或装进集群里；后者公开列出来的核心能力更偏 releases / repositories / plugins 管理，范围明显窄一些。([GitHub][1])

所以如果你问的是：

**“哪个更适合做 Helm 的统一管理面？”**

那我现在会选 **`helm-dashboard`**，不是 `helm-tui`。因为它更接近一个**Helm release 生命周期操作台**，而不是一个“把若干 Helm 子命令包一层终端界面”的工具。它甚至支持 standalone binary 运行，且这种方式下**不要求本机安装 Helm 或 kubectl**；同时也支持作为 Helm plugin 使用、或直接部署到 Kubernetes 集群里。([GitHub][1])

但我还是会把结论分成两层。

## 第一层：如果只比较“工具完成度”

我会这样排：

**Helm 生命周期管理台：`helm-dashboard` > `helm-tui`**

因为 `helm-dashboard` 公开强调的是：

* 已安装 releases 总览
* revision history
* manifest diff
* 关联 K8s resources 浏览
* rollback / upgrade
* 多集群切换
* 本地或集群部署([GitHub][1])

而 `helm-tui` 公开强调的是：

* manage Helm releases
* add / update / remove repositories
* plugins
* 终端内操作([GitHub][2])

也就是说，**如果你的目标是“全面管理 Helm release”而不是“坚持 TUI 形态”**，那 `helm-dashboard` 的确更强。

## 第二层：如果比较“是否兼容我们说的两种常用场景”

这里答案是：

**兼容，但兼容方式不一样。**

### 1）个人 / 小团队：很适合

这类场景下，你前面那套 `helmfile + taskfile` 仍然很合理；而 `helm-dashboard` 可以作为一个很好的**观察 + 临时操作前端**。
因为个人场景里，`upgrade`、`rollback` 这类手工操作成本较低，`helm-dashboard` 又正好把 release、history、diff、resources 放到了一个界面里，所以体验上确实会比 `helm-tui` 更完整。([GitHub][1])

我的建议会是：

* **执行面**：`helmfile + taskfile`
* **观察面 / 临时操作面**：`helm-dashboard`

也就是把它当成 Helm 的“本地控制台”。

### 2）生产环境 + Flux：可以用，但不要把它当主控制面

这里是最关键的分界线。

Flux 的官方模型是：`helm-controller` 通过 `HelmRelease` **声明式**管理 release，支持 install、upgrade、test、uninstall、rollback，并且会持续 reconcile，必要时还会做 **drift correction**。也就是说，**真正的事实来源是 Git 和 `HelmRelease`**，不是某个 UI 里的按钮。([Flux][3])

所以在 Flux 场景里，`helm-dashboard` 的最佳角色是：

* 看 release
* 看 revision / diff
* 看关联资源
* 看健康状态
* 辅助排障

**不应该**把它当成主要写入口去做 upgrade / rollback。
因为你在 UI 里改了 release，Flux 之后还是会按 Git 里的 `HelmRelease` 继续 reconcile，手工改动要么被覆盖，要么造成“到底谁是源头”的混乱。Flux 文档明确强调的是 controller-driven reconciliation 和 drift correction，这和“手点 UI 改 live state”在治理模型上是冲突的。([GitHub][4])

所以我的判断是：

* **个人场景**：`helm-dashboard` 可以接近主 UI
* **Flux 生产场景**：`helm-dashboard` 只能是观察台，不该是主执行面

## 一个必须补的保留意见

我不想把它说得过满。
`helm-dashboard` 和 Flux 并不是“零摩擦完美组合”。GitHub 上至少有一个**历史上的已关闭问题**，提到在 Flux 使用 `storageNamespace` 与 `targetNamespace` 不同的时候，dashboard 查 release 细节会出现 `release: not found`。这说明它和 Flux 的某些高级/非默认用法之间，历史上出现过兼容性边角问题。([GitHub][5])

我不能仅凭这个 issue 就断定现在仍有问题，因为它已经关闭了，而且我没有找到官方文档直接说“已彻底解决”。但这足以说明一件事：

> **在 Flux 场景里，`helm-dashboard` 值得用，但最好先在 staging 验证你的 namespace/storage 模式。** ([GitHub][5])

## 我的最终结论

如果把问题改写成：

**“不是只找 TUI，而是找 Helm 管理/操作的最佳交互工具”**

那我现在会这么下结论：

**`helm-dashboard` 比 `helm-tui` 更值得优先考虑。**
它更全面、更成熟，也更符合“统一看 Helm releases、history、diff、resources、rollback/upgrade”的真实需求。([GitHub][1])

但如果把问题再提升一层，回到我们之前讨论的“管理形态”：

* **个人 / 小团队**：`helmfile + taskfile` 做执行，`helm-dashboard` 做可视化前端，这是很不错的组合。([GitHub][1])
* **生产 / Flux**：`Flux + HelmRelease` 仍然应该是主控制面，`helm-dashboard` 适合做观察和排障界面，不适合取代 GitOps。([Flux][3])

一句话收束：

> **如果比较“工具”，我赞同你，`helm-dashboard` 大概率是比 `helm-tui` 更好的选择；如果比较“控制面”，它仍然应该从属于 `helmfile` 或 `Flux`，而不是取代它们。**

[1]: https://github.com/komodorio/helm-dashboard "GitHub - komodorio/helm-dashboard: The missing UI for Helm - visualize your releases · GitHub"
[2]: https://github.com/pidanou/helm-tui "GitHub - pidanou/helm-tui: A simple terminal UI for Helm · GitHub"
[3]: https://fluxcd.io/flux/guides/helmreleases/ "Manage Helm Releases | Flux"
[4]: https://github.com/fluxcd/helm-controller "GitHub - fluxcd/helm-controller: The GitOps Toolkit Helm reconciler, for declarative Helming · GitHub"
[5]: https://github.com/komodorio/helm-dashboard/issues/37 "Helm releases with different \"storage\" vs \"install\" namespace · Issue #37 · komodorio/helm-dashboard · GitHub"

```













## nix


本身这部分taskfile日常维护都不错

只是移除掉了 `Taskfile.nh.yml`, `Taskfile.nixox-cli.yml` 这两个用不到的 taskfile

并且注释掉了部分已经用处不大的 taskfile

并对整个 `.taskfile` 结构做了个 refactor，每个 domain 提供一个 `Taskfile.yml` 作为入口，方便日常调用（之前添加但是又移除了，因为没意识到可以通过 `flatten` 来控制是否“需要通过 prefix 进行调用”，之前以为只要这种写法就一定要用 prefix）


### Taskfile.store.yml




```yaml
---
# Nix Store 维护相关任务（跨平台）

version: '3'

tasks:
  repair-store:
    desc: "修复 Nix Store 对象"
    summary: "task -g repair-store"
    vars:
      paths: '{{.paths}}'
    cmds:
      - 'echo "🔧 正在修复 Nix Store 对象: {{.paths}}"'
      - nix store repair {{.paths}}

  verify-store:
    desc: "验证 Nix Store 完整性，检查损坏的 store 对象"
    summary: "task -g verify-store"
    cmds:
      - echo "🔍 正在验证 Nix Store 完整性..."
      - nix store verify --all
      - echo "✅ Nix Store 验证完成"

  gcroot:
    desc: "显示所有自动 GC 根目录"
    summary: "task -g gcroot"
    cmds:
      - echo "📂 Nix Store 自动 GC 根目录："
      - ls -al /nix/var/nix/gcroots/auto/

```

移除掉了，现在遇到这种问题都是直接让AI解决，自己手动解决很麻烦








### ***Taskfile.nixos-anywhere.yml***




```yaml
#    ww:
#      - 【练习题】nixos-anywhere 对目标host刷机，必须保证该机器原本的OS是linux吗？还是说windows, darwin 之类的也可以？ # 当然，因为 nixos-anywhere的核心机制就是 kexec，而kexec是linux kernel的专有功能（Windows、macOS（Darwin）或其他非 Linux 系统（如 BSD）根本不支持 kexec，因此无法直接从这些系统启动 NixOS installer）。
#
#    htu:
#      - 【具体流程】核心4步（验、写、跑、验）
#      # 1、验证3项（是否linux、是否SSH能通、是否nixos-anywhere命令可用）
#      ## 测试 SSH 是否连通（注意这步并不需要做SSH免密登录。因为在刷机成功后还要再配置SSH免密，以供colmena使用，所以此时没必要配置）
#      ## 验证 setsid 是否支持 --wait （处理 BusyBox `setsid` 无 `--wait` 导致的 kexec 失败。在部分救援系统（常见于 BusyBox/Alpine 环境）里，预装的 `setsid` 不包含 `--wait` 参数，nixos-anywhere 下载 kexec installer 后会执行 `setsid --wait /root/kexec/kexec/run`，因此直接报错并退出，安装不会继续。）
#
#      # 2、写相应 host（尽量简单（也即只写host的bootstrap层，包括 最小系统（SSH、用户、时区）、disko 布局、必要的网络配置），不要 hm / 大量 modules，加快 rebuild，后面由 colmena push closure）
#
#      # 3、执行 nixos-anywhere 命令（记得先安装 nixos-anywhere命令，记得）
#      ## nix run github:nix-community/nixos-anywhere --flake .#my-host  --target-host root@TARGET_IP  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix
#      ##  实际执行命令 nixos-anywhere  --flake '/home/luck/Desktop/dotfiles#nixos-vps' root@103.85.224.63 --debug --no-reboot
#
#      # 4、验证是否刷机成功（uname, /etc/os-release）
#      # 5、收尾（1、添加该host的SSH 2、添加该host到colmena）
#    hti:
#      - 【核心机制】kexec, disko, install, reboot
#      # kexec phase
#      ## 通过 SSH 登上目标机。
#      ## 如果目标机不是 NixOS installer，就上传一个 NixOS installer 镜像，用 kexec 直接切到一个临时的 NixOS（内核热重启，但是不走 BIOS/UEFI）。
#
#      # disko phase
#      ## 在这个临时 NixOS 里执行 disko，按你的 disk-config.nix：
#      ## 卸载原来的东西
#      ## 划分分区 / 建 ZFS/LUKS/LVM 等
#      ## 格式化
#      ## 挂载到 /mnt 之类的安装路径
#
#      # install phase
#      ## 用 Nix 构建你 flake 里指定的 NixOS system（本地构建 or 目标机构建，由 --build-on 决定）。
#      ## 把构建好的 system closure + disko script 复制到目标机。
#      ## 在目标机上跑 nixos-install 风格的逻辑，把 system 装到刚刚分好的磁盘上。
#
#      # reboot phase
#      ## 卸载 /mnt 的文件系统，必要时 export ZFS 池。
#      ## 重启到新系统。
#      ## 所以你看到的“黑盒”：跑一条命令 → 等若干分钟 → 机器自动重启 → 新 NixOS 起起来，就是这四段东西串在一起。
#
#      # “用 Nix + disko + kexec + ssh 拼出来的 远程全自动 NixOS 装机脚本，你只负责给一份 declarative 配置，它负责帮你：进 installer → 分区 → 安装 → 重启。”
#    hto:
#      - 【dd】

```








## network



***这个必须结合 `network troubleshooting flowchart` 进行处理***



```yaml
Taskfile.yml              # master include
Taskfile.conn.yml         # ping + traceroute + arping + nping (connectivity diagnostics)
Taskfile.dns.yml          # dig (keep as-is, well scoped)
Taskfile.sock.yml         # ss + TCP (socket stats + sysctl)
Taskfile.l2.yml           # iproute2 + ethtool + iw + BPF (interface / L2)
Taskfile.scan.yml         # nmap + naabu (port scanning)
Taskfile.fw.yml           # nft + conntrack (firewall)
Taskfile.l7.yml           # curl + grpcurl + ws + openssl (HTTP/API/TLS)
Taskfile.proxy.yml        # gost + singbox (proxy/tunnel)
Taskfile.perf.yml         # iperf3 (throughput, keep as-is)
Taskfile.chrony.yml       # NTP (keep as-is)
Taskfile.z.yml            # misc playbooks (review & trim)
```











### Taskfile.chrony.yml

NTP相关

直接移除掉，其实用不到



### Taskfile.gost.yml


```yaml
---
version: '3'

tasks:
  # 转发通常是 gost 的最高频用法，因此作为默认入口
  default:
    # score: 4 — recommend: public, gost 端口转发高频
    desc: gost TCP/UDP forward (LISTEN + TARGET)
    summary: "task -g default LISTEN=<addr> TARGET=<addr>"
    vars:
      LISTEN: ''
      TARGET: ''
    # example: task -g gost LISTEN=:8080 TARGET=1.2.3.4:80
    platforms: [linux, darwin]
    preconditions:
      - sh: command -v gost
    requires:
      vars: [LISTEN, TARGET]
    cmds:
      - gost -L {{.LISTEN}} -F {{.TARGET}}

  # 透传模式：适合复杂链路或自定义协议参数
  serve:
    # score: 3 — recommend: public, 复杂链路场景有用但非高频
    desc: gost passthrough (ARGS)
    summary: "task -g serve ARGS=<args>"
    vars:
      ARGS: ''
    # example: task -g gost:serve ARGS="-L socks5://:1080"
    platforms: [linux, darwin]
    preconditions:
      - sh: command -v gost
    requires:
      vars: [ARGS]
    cmds:
      - gost {{.ARGS}}

  # 本地代理：常见的 SOCKS5 与 HTTP proxy
  socks5:
    # score: 4 — recommend: public, 快速起 SOCKS5 代理，高频
    desc: gost SOCKS5 proxy (LISTEN)
    summary: "task -g socks5 LISTEN=<addr>"
    vars:
      LISTEN: ''
    # example: task -g gost:socks5 LISTEN=:1080
    platforms: [linux, darwin]
    preconditions:
      - sh: command -v gost
    requires:
      vars: [LISTEN]
    cmds:
      - gost -L socks5://{{.LISTEN}}

  http:
    # score: 3 — recommend: public, HTTP 代理，有用但 socks5 更常用
    desc: gost HTTP proxy (LISTEN)
    summary: "task -g http LISTEN=<addr>"
    vars:
      LISTEN: ''
    # example: task -g gost:http LISTEN=:8080
    platforms: [linux, darwin]
    preconditions:
      - sh: command -v gost
    requires:
      vars: [LISTEN]
    cmds:
      - gost -L http://{{.LISTEN}}

```





### Taskfile.iperf3.yml

```yaml
# [2026-03-31]
# 本轮调整后，network/perf 只保留 iperf3 相关 task。
#
# 本轮移除的工具级 task：
# - netperf
# - pktgen
# - trafgen
#
# 为什么用 iperf3 替代 netperf：
# - 当前仓库真正需要保留的高频场景，是端到端的 TCP / UDP 吞吐测试。
# - netperf 和 iperf3 在这类场景上高度重叠，继续同时维护两套入口，只会形成重复
#   的心智模型和并行的任务定义。
# - iperf3 更适合作为这里统一的吞吐测试入口，因为它已经足够覆盖常见的 client /
#   server 测试流程，以及并发流、多路压测、双向测试这些高频动作。
#
# 为什么移除 pktgen 和 trafgen：
# - pktgen 和 trafgen 更偏向发包、造流量、报文生成，不是这一轮要保留的端到端吞吐
#   测试工具。
# - 如果继续把它们放在 network/perf 里，这个目录会重新变成 benchmark、packet
#   crafting、traffic generation 混在一起的大杂烩。
# - 本轮的目标是把 network/perf 收敛成“稳定、高频、可重复调用的吞吐测试入口”，
#   因此只保留 iperf3。

```



### Taskfile.nping.yml



```yaml
# [2026-03-31] 删除 hping3，并把保留能力统一收进 Taskfile.nping.yml
#
# 本轮移除的工具级 task：
# - hping3
#
# 为什么保留 nping、删除 hping3：
# - 在当前仓库里，两者保留的高频场景几乎完全重叠，主要都是 ICMP probe 和 PMTU
#   probing。
# - 既然只保留这类“诊断型探测”能力，就没有必要同时维护 hping3 和 nping 两套入口。
# - nping 对当前这组收敛后的场景已经足够，而 hping3 更强也更杂，继续保留会把这层
#   重新带回“可定制 packet 大全集”的方向。
#
# 因此，这里统一只保留 nping 作为增强探测入口。
#
# 进一步说明：
# - 当前保留的 icmp / pmtu 这两个动作，已经覆盖了这里真实需要的 probe 场景。
# - hping3 并不是不能做这些事，而是它的能力范围明显大于当前需求，继续保留会让
#   “少量诊断 task”再次膨胀成“可定制 packet 工具集合”。
# - 因而这轮取舍不是否定 hping3 本身，而是明确把这里的边界收窄为“诊断型 probe”，
#   并统一由 nping 承担。
#
# [2026-03-31] 把 nstat 也整合到了 Taskfile.nping.yml 里
#
# 本轮移除的工具级 task：
# - nstat
#
# 为什么把 nstat 收进这里：
# - nstat 提供的是 ICMP / fragment 相关的 kernel counters 视角，不是新的主入口。
# - 它更适合作为 probe 之后的补充证据，而不是继续单独维护一个 Taskfile。
# - 因此本轮把它收成 nping:stats，和 icmp / pmtu 一起归到“增强探测 + 诊断证据”这层。
```











```yaml
---
version: '3'

# websocat


tasks:
  connect:
    # score: 2 — recommend: internal, WebSocket 客户端连接，场景窄
    desc: websocat connect
    summary: "task -g connect URL=<url>"
    vars:
      URL: ''
    platforms: [linux, darwin]
    requires:
      vars: [URL]
    preconditions:
      - sh: command -v websocat
        msg: websocat not found
    cmds:
      - websocat {{.URL}}

  listen:
    # score: 2 — recommend: internal, WebSocket 服务端监听，场景窄
    desc: websocat listen
    summary: "task -g listen URL=<url>"
    vars:
      URL: ''
    platforms: [linux, darwin]
    requires:
      vars: [URL]
    preconditions:
      - sh: command -v websocat
        msg: websocat not found
    cmds:
      - websocat {{.URL}}

```









```yaml
---
version: '3'

tasks:
  stats:
    # score: 3 — recommend: public, 排查网卡驱动级统计时有用，场景中等
    desc: ethtool stats
    summary: "task -g stats IFACE=<iface>"
    vars:
      IFACE: ''
    platforms: [linux]
    requires:
      vars: [IFACE]
    preconditions:
      - sh: command -v ethtool
        msg: ethtool not found
    cmds:
      # -S: driver stats
      - sudo ethtool -S {{.IFACE}}

  info:
    # score: 4 — recommend: public, ethtool 基础信息查看，接口诊断高频
    desc: ethtool info
    summary: "task -g info IFACE=<iface>"
    vars:
      IFACE: ''
    platforms: [linux]
    requires:
      vars: [IFACE]
    preconditions:
      - sh: command -v ethtool
        msg: ethtool not found
    cmds:
      - sudo ethtool {{.IFACE}}

```



```yaml
---
version: '3'

tasks:
  s_client:
    # score: 4 — recommend: public, 排查 TLS 握手问题高频
    desc: openssl s_client (TLS handshake)
    summary: "task -g s_client HOST=<host> PORT=<port>"
    vars:
      HOST: ''
      PORT: ''
    platforms: [linux, darwin]
    requires:
      vars: [HOST, PORT]
    preconditions:
      - sh: command -v openssl
        msg: openssl not found
    cmds:
      # -servername: SNI
      - openssl s_client -connect {{.HOST}}:{{.PORT}} -servername {{.HOST}}

  x509:
    # score: 3 — recommend: public, 查看证书详情，排查证书问题时有用
    desc: openssl x509 view cert
    summary: "task -g x509 CERT=<path>"
    vars:
      CERT: ''
    platforms: [linux, darwin]
    requires:
      vars: [CERT]
    preconditions:
      - sh: command -v openssl
        msg: openssl not found
    cmds:
      - openssl x509 -noout -text -in {{.CERT}}

```




### Taskfile.ssh.yml

<details>
<summary>Taskfile.ssh.yml</summary>

```yaml
---
version: '3'


# sshpass -p '<pass>' ssh -t -o StrictHostKeyChecking=no luck@192.168.71.7 'cd /home/luck/nix-config && echo "<pass>" | sudo -S nixos-rebuild switch --flake .#nixos-ws 2>&1 | tail -100'

env:
  SSH_KEY_TYPE: ed25519
  SSH_KEY_DIR: ~/.ssh

tasks:

  default:
    # score: 3 — recommend: public, 新机器 SSH 初始化全流程，偶尔用
    desc: Setup SSH for a new host
    summary: "task -g setup-ssh"
    cmds:
      - task: generate-key
      - task: copy-key
      - task: set-permissions

  # 默认使用 rsa 算法生成key，但是建议使用 ed25519算法，更安全更快。使用 -C 来标识，比如说github就标识gh，我通常直接把 identifier 和 passphrase密码 设置为相同的，防止忘掉。产生公钥与私钥对，其中id_rsa 私钥，保留不动即可，后续 ssh 命令会自动读取此文件。id_rsa.pub 公钥，此文件需要被保存至目标服务器，用作验证。
  generate-key:
    # score: 3 — recommend: public, 生成 SSH 密钥，加新机器时有用
    desc: 生成 SSH 密钥对（task -g ssh:generate-key HOST_ALIAS=github）
    summary: "task -g generate-key HOST_ALIAS=<name>"
    vars:
      HOST_ALIAS: '{{.HOST_ALIAS | default ""}}'
      SSH_KEY_DIR: '{{.SSH_KEY_DIR | default "~/.ssh"}}'
      SSH_KEY_TYPE: '{{.SSH_KEY_TYPE | default "ed25519"}}'
    requires:
      vars: [HOST_ALIAS]
    cmds:
      - ssh-keygen -t {{.SSH_KEY_TYPE}} -C "{{.HOST_ALIAS}}" -f {{.SSH_KEY_DIR}}/id_{{.HOST_ALIAS}}
  # ssh-keygen -t ed25519 -f my_github_ed25519  -C "me@github"
  # ssh-keygen -t ed25519 -f my_gitee_ed25519   -C "me@gitee" # 我在 Gitee
  # ssh-keygen -t ed25519 -f my_gitlab_ed25519  -C "me@gitlab" # 我在 GitLab
  # ssh-keygen -t ed25519 -f my_company_ed25519 -C "email@example.com" # 我在企业
  # 产生公钥与私钥对
  # id_rsa 私钥，保留不动即可，后续 ssh 命令会自动读取此文件。
  # id_rsa.pub 公钥，此文件需要被保存至目标服务器，用作验证。



  # 上传公钥到目标服务器（将本机的公钥复制到远程机器的authorized_keys文件中）
  # 相当于 pbcopy命令。
  # ⚠️ 复制之后最好在服务端验证一下。
  copy-key:
    # score: 3 — recommend: public, 上传公钥到服务器，加机器时有用
    desc: 上传公钥到目标服务器（task -g ssh:copy-key ）
    summary: "task -g copy-key HOST=<host> HOST_ALIAS=<name>"
    vars:
      HOST: '{{.HOST | default ""}}'
      HOST_ALIAS: '{{.HOST_ALIAS | default ""}}'
      SSH_KEY_DIR: '{{.SSH_KEY_DIR | default "~/.ssh"}}'
    requires:
      vars: [HOST, HOST_ALIAS]
    cmds:
      - ssh-copy-id -i {{.SSH_KEY_DIR}}/id_{{.HOST_ALIAS}}.pub {{.USER}}@{{.HOST}}
  #  ssh-copy-id <user>@<ip>
  #  # 指定 pub
  #  ssh-copy-id -i <~/.ssh/id_rsa.pub> <user>@<ip>



  # 在 客户端 设置权限
  # 修改 known_hosts文件 的权限
  # 修改 私钥和公钥 的权限
  set-permissions:
    # score: 2 — recommend: internal, 设置 SSH 文件权限，手动 chmod 就够了
    desc: Set SSH file permissions
    summary: "task -g set-permissions HOST_ALIAS=<name>"
    vars:
      HOST_ALIAS: '{{.HOST_ALIAS | default ""}}'
      SSH_KEY_DIR: '{{.SSH_KEY_DIR | default "~/.ssh"}}'
    requires:
      vars: [HOST_ALIAS]
    cmds:
      - chmod 755 {{.SSH_KEY_DIR}}
      - chmod 600 {{.SSH_KEY_DIR}}/id_{{.HOST_ALIAS}}
      - chmod 600 {{.SSH_KEY_DIR}}/id_{{.HOST_ALIAS}}.pub
      - chmod 644 {{.SSH_KEY_DIR}}/known_hosts


#  verify:
#    # score: 2 — recommend: internal, 验证私钥格式，一次性场景
#    desc: "task -g ssh:verify PPK_PATH=/etc/ssh/github/private_key"
#    summary: "task -g verify PPK_PATH=<path>"
#    vars:
#      PPK_PATH: '{{.PPK_PATH | default ""}}'
#    requires:
#      vars: [PPK_PATH]
#    cmd: ssh-keygen -y -e -f {{.PPK_PATH}} >/dev/null && echo "格式合法" || echo "仍不合法"


  clear:
    # score: 3 — recommend: public, 从 known_hosts 删除旧记录，换 IP 时有用
    desc: 从 $HOME/.ssh/known_hosts 里删除旧记录 # 之前一直是直接删除掉整个文件的，实际上可以通过该命令只删除指定host，不影响其他host
    summary: "task -g clear HOST=<host>"
    vars:
      HOST: '{{.HOST | default ""}}'
    requires:
      vars: [HOST]
    cmd: ssh-keygen -R {{.HOST}}

```


</details>


上面这一坨里，其实真正有用的就3条命令


```shell

# ssh-keygen -t {{.SSH_KEY_TYPE}} -C "{{.HOST_ALIAS}}" -f {{.SSH_KEY_DIR}}/id_{{.HOST_ALIAS}}
# ssh-keygen -t ed25519 -C "xxx" -f ~/.ssh/id_xxx

ssh-copy-id user@host

# 从 $HOME/.ssh/known_hosts 里删除旧记录
ssh-keygen -R {{.HOST}}
```


- 1、正常来说临时场景，只需要直接 ssh-copy-id 就可以了，不需要ssh-keygen（因为本地是有 `id_ed25519` 的，不需要给某个VPS单独再生成一套 key-pair）
- 2、`set-permissions` 在现代 ssh-keygen 下是多余的（自动设权限）

OpenSSH 的 ssh-keygen.c 在 do_gen_key

```cgo
// 私钥: owner read/write only
chmod(identity_file, 0600);
// 公钥: owner read/write, group/world read
chmod(public_key_file, 0644);
```

完全绕过 umask，生成即设好，不需要手动 chmod。




## kernel








### Taskfiles.pkg.yml



这是我之前写的一个taskfile
从来没用过，你觉得这东西有用吗？我是感觉是那种看起来很有用，实则压根没有使用场景的东西

你觉得呢？做个综合判断


---


我来补充一些 context

主要是因为我的核心场景就是 NixOS

而我给 nixos本身打包了一套taskfile，我日常更多使用那个

并且对于nixos来说，nixpkgs几乎不存在用命令安装的场景，所以我就没怎么用过

另外，这个taskfile存在一个分发问题，如果可以作为 remote taskfile 直接运行，那么就会常用很多，你觉得呢？我记得现在 taskfile 是支持remote调用了

或者说如果想把这个taskfile用起来，有其他什么方案吗？





```markdown
• 综合判断：**你这份 .taskfile/kernel/.Taskfile.pkg.yml 在你当前工作流里，确实更
  像“看起来通用，实际很少会触发”的东西。**不是它设计得差，而是它解决的问题和你的
  主场景错位了。

  先说结论。

  1. 对你个人来说，它现在实用价值偏低。
  2. 对“跨发行版临时操作 / 教程式速查 / 远程一次性调用”来说，它有潜在价值。
  3. 如果不改定位，继续保留成一个本地常驻 taskfile，大概率还是会吃灰。

  核心原因很直接：

  - 你的主场景是 NixOS，而且你已经有一套更贴近日常的 NixOS task 体系。
  - 这份文件是“跨 distro 包管理命令抽象层”，但你平时并不真的在 Arch / Debian /
    Fedora 之间来回切换包管理。
  - 对 NixOS 而言，这里面不少动作本身就不是你的主路径，比如 nix-env -i、nix-
    channel --update 这类更偏旧式 CLI；而你真实工作更可能围绕 flake、HM、nixos-
    rebuild、项目级 task 展开。
  - 从仓库结构看，它现在也没有进入主入口 includes，基本印证了“写过，但没进入主工
    作流”。

  更关键的一点是：它的抽象层级有点假统一。
  install/search/remove/upgrade 这些词在不同发行版上表面相似，但语义并不完全等
  价。对 apt/pacman/dnf 还勉强能做“速查入口”，到了 NixOS 就开始别扭，因为 Nix 的
  安装、查询、系统升级，本来就不是同一套心智模型。结果就是：

  - 作为“统一接口”，不够真。
  - 作为“NixOS 工具”，又不够贴身。

  所以你会产生“看起来有用，实际上没场景”的感觉，这个判断我基本认同。

  关于你说的 remote taskfile，我查了官方文档，答案是：

  - 是支持的，可以 task -t <remote-uri>，也可以 includes: 远程 Taskfile。
  - 但截至当前官方文档，它仍然是 experimental，需要开启
    TASK_X_REMOTE_TASKFILES=1。
  - 官方还明确提醒不要在生产场景依赖实验特性，并强调信任与缓存问题。

  参考：

  - Remote Taskfiles: https://taskfile.dev/docs/experiments/remote-taskfiles
  - CLI --taskfile: https://taskfile.dev/docs/reference/cli
  - Taskfile versioning: https://taskfile.dev/docs/taskfile-versions

  所以我的判断是：remote 会显著提升“偶尔用一下”的概率，但还不足以成为你应该押注的
  主分发方案。
  它适合这种场景：

  - 你在一台临时机器上，想快速拿到一组 task
  - 你想把它当“共享脚本入口”发给别人
  - 你愿意接受实验特性带来的启用门槛和稳定性不确定性

  但如果你问“这样能不能让它变成日常高频工具”，我觉得答案还是偏否。因为问题的根本
  不是“调用成本太高”，而是需求频率本身不高。

  如果你想把这个东西“救活”，我觉得有三条路，只有前两条值得认真考虑：

  1. 改定位，收缩成 Nix 相关的 pkg helper

  - 不再做跨 distro 统一层。
  - 只保留你真的会用的动作，比如 search、locate-file、why-depends、profile-list、
    shell、run 之类。
  - 这样它才能和你的 NixOS 主工作流贴合，而不是和它竞争。

  2. 改成远程速查/一次性入口

  - 把它定义成“临时机器 bootstrap 的命令词典”。
  - 接受它不是高频本地 task，而是“偶尔 remote 拉一下”的工具。
  - 这时 remote taskfile 的价值就成立了，哪怕还是 experimental。

  3. 降级为文档，不再强求执行入口

  - 如果它本质是 cheatsheet，就把它变成 cheatsheet。
  - 有些东西写成 Taskfile 并不会比写成一页清晰文档更有用，尤其当参数、语义差异、
    权限要求都不一致时。

  如果是我来定，我会这样处理：

  - 如果你只关心个人实际使用率：删掉或归档。
  - 如果你想保留这部分知识资产：把它改造成“远程可调用的 bootstrap/cheatsheet
    taskfile”，并明确标注 experimental。
  - 如果你希望它融入日常：重写成 Nix-only 的 pkg/task 工具，而不是跨 distro
    abstraction。

  再补一句比较关键的判断：
  你现在这份文件里对 NixOS 的映射，本身就已经说明它不是围绕你当前系统设计的，而是
  把 NixOS 硬塞进“传统包管理器并列项”里。这不是分发问题，是产品定位问题。remote
  只能解决“更容易拿到”，解决不了“拿到以后还是不太想用”。

  本地参考：

  - .taskfile/kernel/.Taskfile.pkg.yml
  - home/base/core/taskfile.nix:1
  - .taskfile/Taskfile.yml:1

  如果你愿意，我下一步可以直接帮你做两件事里的一件：

  1. 把这份 pkg taskfile 重构成 Nix-only、你会真的用的版本
  2. 把它改造成一个 适合 remote 调用的公共 Taskfile，顺手把调用方式和风险边界也定
     下来
^C
```



最终直接重新做成 YAML Table 了




### Taskfile.journalctl.yml






### Taskfile.power.yml

<details>
<summary>Taskfile.power.yml</summary>

```yaml

---
version: "3"

vars:
  # MEM_SLEEP: kernel mem_sleep policy (s2idle|deep)
  MEM_SLEEP: '{{.MEM_SLEEP | default "deep"}}'
  # WAKE_SECONDS: RTC wakealarm offset (seconds)
  WAKE_SECONDS: '{{.WAKE_SECONDS | default "600"}}'
  # TAIL_LINES: journalctl lines to show
  TAIL_LINES: '{{.TAIL_LINES | default "200"}}'
  # GREP_PM: log keywords for power management
  GREP_PM: '{{.GREP_PM | default "PM:|suspend|hibernate|sleep|wakeup|Freeze|resume"}}'

tasks:
  _check:systemd:
    internal: true
    platforms: [linux]
    preconditions:
      - sh: command -v systemctl >/dev/null 2>&1
        msg: "systemctl not found (systemd required)"
      - sh: command -v journalctl >/dev/null 2>&1
        msg: "journalctl not found (systemd required)"

  power:info:
    desc: Power info summary (kernel + mem_sleep + inhibitors)
    summary: "task -g power:info"
    platforms: [linux]
    cmds:
      - uname -a
      - cat /sys/power/state
      - cat /sys/power/mem_sleep
      - task: power:inhibitors

  power:inhibitors:
    desc: List sleep inhibitors (systemd-inhibit + loginctl)
    summary: "task -g power:inhibitors"
    platforms: [linux]
    preconditions:
      - sh: command -v systemd-inhibit >/dev/null 2>&1
        msg: "systemd-inhibit not found"
      - sh: command -v loginctl >/dev/null 2>&1
        msg: "loginctl not found"
    cmds:
      - systemd-inhibit --list
      - loginctl inhibit --list

  power:memsleep:get:
    desc: Show current mem_sleep (s2idle/deep)
    summary: "task -g power:memsleep:get"
    platforms: [linux]
    preconditions:
      - sh: test -r /sys/power/mem_sleep
        msg: "/sys/power/mem_sleep not readable"
    cmds:
      - cat /sys/power/mem_sleep
      - cat /sys/power/state

  power:memsleep:set:
    desc: Set mem_sleep (MEM_SLEEP=s2idle|deep)
    summary: "task -g power:memsleep:set"
    platforms: [linux]
    preconditions:
      - sh: test -w /sys/power/mem_sleep
        msg: "need root or writable /sys/power/mem_sleep"
    cmds:
      - echo "{{.MEM_SLEEP}}" | sudo tee /sys/power/mem_sleep >/dev/null
      - cat /sys/power/mem_sleep

  power:suspend:
    desc: Trigger suspend (Sleep / STR)
    summary: "task -g power:suspend"
    deps:
      - '_check:systemd'
    platforms: [linux]
    cmds:
      - systemctl suspend
      - task: power:logs

  power:hibernate:
    desc: Trigger hibernate (Hibernate / STD)
    summary: "task -g power:hibernate"
    deps:
      - '_check:systemd'
    platforms: [linux]
    cmds:
      - systemctl hibernate
      - task: power:logs

  power:hybrid:
    desc: Trigger hybrid-sleep (Sleep + Hibernate)
    summary: "task -g power:hybrid"
    deps:
      - '_check:systemd'
    platforms: [linux]
    cmds:
      - systemctl hybrid-sleep
      - task: power:logs

  power:sth:
    desc: Trigger suspend-then-hibernate (Standby)
    summary: "task -g power:sth"
    deps:
      - '_check:systemd'
    platforms: [linux]
    cmds:
      - systemctl suspend-then-hibernate
      - task: power:logs

  power:wake:rtc:set:
    desc: Set RTC wakealarm (WAKE_SECONDS)
    summary: "task -g power:wake:rtc:set"
    platforms: [linux]
    preconditions:
      - sh: test -w /sys/class/rtc/rtc0/wakealarm
        msg: "need root or writable /sys/class/rtc/rtc0/wakealarm"
    cmds:
      - echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm >/dev/null
      - echo +{{.WAKE_SECONDS}} | sudo tee /sys/class/rtc/rtc0/wakealarm >/dev/null

  power:wake:rtc:clear:
    desc: Clear RTC wakealarm
    summary: "task -g power:wake:rtc:clear"
    platforms: [linux]
    preconditions:
      - sh: test -w /sys/class/rtc/rtc0/wakealarm
        msg: "need root or writable /sys/class/rtc/rtc0/wakealarm"
    cmds:
      - echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm >/dev/null
      - cat /sys/class/rtc/rtc0/wakealarm

  power:logs:
    desc: Power-related logs (journalctl + dmesg)
    summary: "task -g power:logs"
    deps:
      - '_check:systemd'
    platforms: [linux]
    set: [pipefail]
    cmds:
      - journalctl -b --no-pager -n {{.TAIL_LINES}} | grep -iE "{{.GREP_PM}}"
      - journalctl -b -u systemd-logind --no-pager -n {{.TAIL_LINES}}
      - dmesg -T | grep -iE "{{.GREP_PM}}"


```

</details>








```markdown
综合判断：**有意义，但不是“高质量资产”，更像“个人 Linux 电源管理调试工具箱”**。我会给它 **6/10**：方向对，覆盖点也对，但实现上有几处会让它在关键时刻掉链子。

从官方能力模型看，这个 Taskfile 选的切入点并不虚。systemd 本来就把 `suspend`、`hibernate`、`hybrid-sleep`、`suspend-then-hibernate` 当成标准睡眠模式；Linux 内核也确实通过 `/sys/power/mem_sleep` 暴露 `s2idle` / `deep` 这类策略切换。所以它把“触发睡眠、看 inhibitor、切 mem_sleep、查日志、设 RTC 唤醒”这些动作收在一起，作为**排障入口集合**，是成立的。([自由桌面][1])

它真正的价值主要在三件事。第一，把零散命令收口成统一入口，少记命令。第二，`mem_sleep` 和 RTC wakealarm 这两块，确实是调试“为什么睡不深 / 为什么唤不醒 / 为什么 suspend-then-hibernate 行为怪”的高频点。第三，它把 destructive 操作和日志查询放在同一个命名空间里，使用心智负担比较低。尤其是 `s2idle` vs `deep`，内核文档明确把它们当成不同的 suspend 路径，这不是“伪开关”。([Linux内核文档][2])

但它的问题也很明显，而且有几个是“设计上会误导人”的级别。

第一，**有些 task 只是给单条命令套了个壳**。例如 `power:suspend` / `power:hibernate` / `power:hybrid` / `power:sth`，本质就是 `systemctl xxx`。如果你不是反复做实验，Taskfile 带来的增益不大，维护成本反而上来了。

第二，**`power:inhibitors` 很可能写错了半边**。官方文档明确给出的 inhibitor 列表接口是 `systemd-inhibit --list`；而 `loginctl` 官方命令摘要里是各种 session/user/seat 操作，我没看到一个与 `loginctl inhibit --list` 对应的标准列举命令。所以这里至少是“非常可疑”，很可能直接跑不通。([自由桌面][3])

第三，**几个需要 root 的 precondition 和后面的 `sudo tee` 逻辑是打架的**。
像这类：



非 root 用户通常会在 precondition 就被挡住，根本走不到 `sudo tee`。也就是说，它表面上支持 sudo，实际上前置检查先把你拒之门外了。这是典型“看起来贴心，其实不可用”。

第四，**`power:logs` 很脆**。你开了 `pipefail`，但 `journalctl ... | grep -iE ...` 在“没有匹配日志”时会返回 1，于是整个 task 失败。对排障来说，“没匹配到”本来应该是一个信息，不应该被当成执行失败。现在这个设计会制造很多假阳性。

第五，**缺少能力检测**。
既然 systemd 的睡眠模式是系统能力相关的，那在执行前最好先检查“这台机器能不能 suspend / hibernate / hybrid-sleep / suspend-then-hibernate”。否则 task 名字很完整，用户预期很高，但失败时体验会像“脚本坏了”，其实可能只是机器没配置好。官方 systemd 也把这些睡眠模式视为依赖系统配置和平台支持的能力，而不是无条件可用。([自由桌面][1])

第六，**硬编码太重**。`/sys/class/rtc/rtc0/wakealarm`、`dmesg -T`、systemd 环境、Linux 平台，这些都说明它是“某一类机器上的私人工具”，不是“可推广的通用 task 集”。这没错，但要承认它的边界。

所以我的最终判断是：

* **如果你的目标是个人机排障**：它有意义，值得留，但要修。
* **如果你的目标是团队共享**：现在还不够格，得重构。
* **如果你的目标只是“把常用命令记下来”**：它有点过度工程化了，精简成 4 到 6 个核心 task 更合适。

我会怎么处理：

1. **保留**
   `power:info`、`power:memsleep:get`、`power:logs`、`power:wake:rtc:set/clear`

2. **修掉**
   `loginctl inhibit --list`
   root precondition
   `grep` 导致的假失败

3. **补上**
   睡眠能力检查
   更明确的错误提示
   `power:sth` 改个更好懂的名字

4. **考虑删除或合并**
   那几个纯 `systemctl xxx` 包装 task，除非你真的高频使用

一句话收尾：**它不是“没意义”，而是“有明确场景价值，但工程完成度不高”**。保留可以，前提是把它定位成“本机电源调试手册”，别把它当成熟工具链。

如果你愿意，我可以直接把它改成一个“保留价值、去掉坑点”的精简版 Taskfile。

[1]: https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html?utm_source=chatgpt.com "systemd-sleep.conf - freedesktop.org"
[2]: https://docs.kernel.org/admin-guide/pm/sleep-states.html?utm_source=chatgpt.com "System Sleep States — The Linux Kernel documentation"
[3]: https://www.freedesktop.org/software/systemd/man/latest/systemd-inhibit.html?utm_source=chatgpt.com "systemd-inhibit - freedesktop.org"

```








### Taskfile.user.yml



```yaml
---
version: "3"

vars:
  USER_MGR: "{{.TASKFILE_DIR}}/scripts/user-manager.sh"

tasks:
  _call:
    vars:
      FUNC: ''
    internal: true
    platforms: [linux]
    requires:
      vars: [FUNC]
    cmds:
      - cmd: |
          source "{{.USER_MGR}}"
          check_root
          {{.FUNC}}

  create:
    desc: 创建普通用户（交互）
    summary: "task -g create"
    # example: task -g user:create
    platforms: [linux]
    interactive: true
    cmds:
      - task: _call
        vars: {FUNC: create_user}

  create-admin:
    desc: 创建管理员用户（交互）
    summary: "task -g create-admin"
    # example: task -g user:create-admin
    platforms: [linux]
    interactive: true
    cmds:
      - task: _call
        vars: {FUNC: create_admin}

  passwd:
    desc: 修改用户密码（交互）
    summary: "task -g passwd"
    # example: task -g user:passwd
    platforms: [linux]
    interactive: true
    cmds:
      - task: _call
        vars: {FUNC: change_password}

  list:
    desc: 列出普通用户（UID >= 1000）
    summary: "task -g list"
    # example: task -g user:list
    platforms: [linux]
    cmds:
      - task: _call
        vars: {FUNC: list_users}

  delete:
    desc: 删除用户（交互）
    summary: "task -g delete"
    # example: task -g user:delete
    platforms: [linux]
    interactive: true
    cmds:
      - task: _call
        vars: {FUNC: delete_user}

```




### Taskfile.shell.yml



<details>
<summary>Taskfile.shell.yml</summary>

```yaml
---
version: '3'

vars:
  DEFAULT_SHELL_PATH:
    sh: echo $SHELL # 显示为用户设置的默认 Shell（定义在 /etc/passwd 中），但不一定是当前 Shell
  CURRENT_SHELL_PATH:
    sh: echo $0 # 显示当前会话正在使用的 Shell 名称（如 bash, zsh）
  SHELLS:
    sh: grep -v '^#' /etc/shells # 列出目前所有可用的shell


tasks:
  default-shell:
    desc: 显示用户的默认shell
    summary: "task -g default-shell"
    cmds:
      - echo "用户默认的Shell {{.DEFAULT_SHELL_PATH}}"

  list:
    desc: 列出系统所有可用的合法shell
    summary: "task -g list"
    interactive: true
    cmds:
      - for:
          var: SHELLS
          as: SHELL
        cmd: "{{.SHELL}} --version 2>/dev/null || echo not support"
    preconditions:
      - sh: command -v chsh
        msg: chsh not found


#  shell-env:
#    desc: 查看与shell相关的环境变量
#    summary: "task -g shell-env"
#    cmds:
#      - echo "与Shell相关的环境变量:"
#      - env | grep -i shell

#  switch:
#    desc: 临时切换当前会话的 Shell。退出（exit）后恢复原 Shell，不影响默认设置
#    summary: "task -g switch"
#    cmd: exec zsh

  change:
    desc: 永久修改默认shell（需要重新登录生效）
    summary: "task -g change"
    interactive: true
    cmds:
      - chsh -s {{.SELECTED}}
    vars:
      SELECTED:
        sh: gum choose {{.SHELLS | splitLines | join " "}} # {{.SHELLS | catLines | trim}} 这里需要注意因为SHELLS返回的并非数组，而是一个多行字符串，所以需要splitLines处理为数组
        msg: 选择指定shell
    preconditions:
      - sh: command -v gum
        msg: gum not found
      - sh: command -v chsh
        msg: chsh not found


  test:
    desc: 测试bash启动时间
    summary: "task -g test"
    interactive: true
    cmds:
      - time bash -i -c exit
      - time zsh -i -c exit

```

</details>



### Taskfile.systemd.yml



<details>
<summary>Taskfile.systemd.yml</summary>


```yaml
---
version: '3'


# systemd-cgtop
#显示控制组（cgroup）的资源使用情况（类似 top）。
#示例：systemd-cgtop
#systemd-cgls
#列出控制组的层级结构。
#示例：systemd-cgls
#systemd-run
#临时运行一个命令作为 systemd 单元。
#示例：systemd-run --unit=mycommand sleep 60
#systemd-escape
#将字符串转换为适合 systemd 单元名称的格式。
#示例：systemd-escape "my service"（输出：my\x20service）
#systemd-notify
#通知 systemd 服务状态（通常在脚本中使用）。
#示例：systemd-notify --ready
#systemd-resolve
#管理 DNS 解析（在较老版本中使用，部分功能已移至 resolvectl）。
#示例：systemd-resolve --status
#resolvectl
#管理 DNS 解析（替代 systemd-resolve）。
#
#resolvectl status
#显示 DNS 解析状态。
#resolvectl set-dns <IP>
#设置 DNS 服务器。
#示例：resolvectl set-dns 8.8.8.8
#
#
#systemd-inhibit
#临时禁止系统进入某些状态（如休眠、关机）。
#示例：systemd-inhibit --what=shutdown sleep 3600
#systemd-nspawn
#运行轻量级容器。
#示例：systemd-nspawn -D /path/to/container
#systemd-tmpfiles
#管理临时文件和目录。
#
#systemd-tmpfiles --create
#创建配置文件中定义的临时文件。
#systemd-tmpfiles --clean
#清理过期临时文件。
#
#
#systemd-delta
#显示系统单元文件与默认配置的差异。
#示例：systemd-delta
#systemd-path
#显示 systemd 使用的路径。
#示例：systemd-path
#systemd-ask-password
#提示用户输入密码（用于脚本或服务）。
#示例：systemd-ask-password "Enter password:"
#systemd-socket-activate
#测试 socket 激活的单元。
#示例：systemd-socket-activate -l 8080



#  单元类型：systemd 管理多种单元，包括 .service（服务）、.target（运行目标）、.socket（套接字）、.timer（定时器）、.mount（挂载点）、.slice（资源控制组）等。上述命令中 <unit> 可以替换为具体的单元名称，如 nginx.service 或 multi-user.target。

#  配置文件：单元文件通常位于 /etc/systemd/system/（用户自定义）或 /usr/lib/systemd/system/（系统默认）。

#  日志持久化：journalctl 的日志默认存储在内存中，若需持久化，需配置 /etc/systemd/journald.conf 中的 Storage=persistent。



# MAYBE: [2026-04-20] 联动 systemd-manager-tui 这几个TUI，两点问题：1、本taskfile没有达到我的预期，其实应该直接vars里直接走 gum choose 选择相应 ACTION，但是现在这个，即使用了通配符，仍然需要手动输入ACTION，不便使用。2、不确定这几个TUI在多大程度上能替代这个taskfile，但是高频操作是可以替代掉的。

tasks:
# 服务管理组
  service:*:
    desc: Manage systemd services (start/stop/restart/etc.)
    summary: "task -g sysd:service:<ACTION> [UNIT]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      UNIT: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - start
            - stop
            - restart
            - reload
            - reload-or-restart
            - enable
            - disable
            - mask
            - unmask
            - daemon-reload
            - reset-failed
    cmds:
      - echo "Starting {{.ACTION}}"
      - systemctl {{.ACTION}} {{.UNIT}}

# 状态查询组
  status:*:
    desc: Query systemd unit status/listing
    summary: "task -g sysd:status:<ACTION> [UNIT]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      UNIT: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - status
            - active
            - enabled
            - failed
            - list
            - list-all
            - list-services
            - list-failed
            - list-files
            - list-dependencies
            - get-default
    cmds:
      - echo "Starting {{.ACTION}}"
      - systemctl {{.ACTION}} {{.UNIT}}

# 系统管理组
  system:*:
    desc: Manage system power/boot targets
    summary: "task -g sysd:system:<ACTION> [TARGET]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      TARGET: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - reboot
            - poweroff
            - halt
            - suspend
            - hibernate
            - hybrid-sleep
            - rescue
            - emergency
            - default
            - isolate
            - set-default
    cmds:
      - echo "Starting {{.ACTION}}"
      - systemctl {{.ACTION}} {{.TARGET}}


# curl -vk --resolve beszel.lucc.dev





# 性能分析组
  analyze:*:
    desc: Run systemd-analyze subcommands
    summary: "task -g sysd:analyze:<ACTION> [UNIT]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      UNIT: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - analyze
            - blame
            - critical-chain
            - plot
            - dot
            - verify
            - unit-files
            - security
    cmds:
      - echo "Starting {{.ACTION}}"
      - systemd-analyze {{.ACTION}} {{.UNIT}}

# 用户会话组
  login:*:
    desc: Manage login sessions/users with loginctl
    summary: "task -g sysd:login:<ACTION> [PARAM]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      PARAM: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - list-sessions
            - session-status
            - terminate-session
            - list-users
            - kill-user
            - user-status
            - lock-session
            - unlock-session
    cmds:
      - echo "Starting {{.ACTION}}"
      - loginctl {{.ACTION}} {{.PARAM}}

# 主机名管理组
  hostname:*:
    desc: Manage system hostname
    summary: "task -g sysd:hostname:<ACTION> [VALUE]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      VALUE: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - status
            - set-hostname
    cmds:
      - echo "Starting {{.ACTION}}"
      - hostnamectl {{.ACTION}} {{.VALUE}}

 # 本地化管理组
  locale:*:
    desc: Manage locale/keymap settings
    summary: "task -g sysd:locale:<ACTION> [VALUE]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      VALUE: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - status
            - set-locale
            - set-keymap
            - list-locales
            - list-keymaps
    cmds:
      - echo "Starting {{.ACTION}}"
      - localectl {{.ACTION}} {{.VALUE}}

# 时间管理组
  time:*:
    desc: Manage time/ntp/timezone
    summary: "task -g sysd:time:<ACTION> [VALUE]"
    vars:
      ACTION: '{{index .MATCH 0}}'
      VALUE: '{{index .MATCH 1 | default ""}}'
    requires:
      vars:
        - name: ACTION
          enum:
            - status
            - set-time
            - set-timezone
            - set-ntp
            - list-timezones
    cmds:
      - echo "Starting {{.ACTION}}"
      - timedatectl {{.ACTION}} {{.VALUE}}


  list-inactive:
    desc: "列出非活跃系统服务"
    summary: "task -g sysd:list-inactive"
    interactive: true
    silent: true
    cmds:
      - systemctl list-units -all --state=inactive

  list-failed:
    desc: "列出失败的系统服务"
    summary: "task -g sysd:list-failed"
    interactive: true
    silent: true
    cmds:
      - systemctl list-units -all --state=failed

  list-systemd:
    desc: "列出 systemd 相关服务"
    summary: "task -g sysd:list-systemd"
    interactive: true
    silent: true
    cmds:
      - systemctl list-units systemd-*

```


</details>



:::tip

直接用TUI替代了

选择使用 `systemd-manager-tui` 而非 `systemctl-tui`

首先排除掉isd，因为是python写的


---

如果你要的是“日常高频运维手感”，我更偏向 systemctl-tui。

原因不是它功能更多，恰恰相反，是它收得更狠：服务状态、日志、start/stop/restart/reload、编辑 unit file，这条路径非常清楚；再加上一键安装脚本、明确的 x64/ARM64 发布、以及更近的 release 信号，说明它更像一个“天天打开”的工具。

如果你要的是“systemd 管理面更完整”，那 systemd-manager-tui 更合适。

尤其是你明确在意 enable/disable、mask/unmask、system/user units 切换、只看 running、Vim-like 导航这些“管理员视角”的能力时，它的功能边界更贴近“控制台”。

一句话总结：

- 偏日常操作效率：systemctl-tui
- 偏完整管理能力：systemd-manager-tui


:::




```markdown
systemd-manager-tui 不能整份替代你的 taskfile。

但它可以替掉你 taskfile 中最常用、最适合交互式完成的部分，也就是：

建议交给 systemd-manager-tui 的

- service:start
- service:stop
- service:restart
- service:enable
- service:disable
- service:mask
- service:unmask
- status:status
- status:list
- status:list-all
- status:list-services
- status:active
- status:failed
- status:list-failed
- list-inactive
- list-failed
- list-systemd


建议继续保留在 taskfile / shell 的

- service:reload
- service:reload-or-restart
- service:daemon-reload
- service:reset-failed
- status:enabled
- status:list-files
- status:list-dependencies
- status:get-default
- 整组 system:*
- 整组 analyze:*
- 整组 login:*
- 整组 hostname:*
- 整组 locale:*
- 整组 time:*

```




### Taskfile.cgroup.yml


<details>
<summary>Taskfile.cgroup.yml</summary>

```yaml
---
version: "3"

vars:
  # PID: 目标进程 PID
  PID: '{{.PID | default "1"}}'
  # CGROUP_PATH: cgroup v2 在 /sys/fs/cgroup 下的相对路径
  CGROUP_PATH: '{{.CGROUP_PATH | default "system.slice"}}'

tasks:
  proc:cgroup:detect:
    desc: Detect cgroup version (v1/v2)
    summary: "task -g proc:cgroup:detect"
    platforms: [linux]
    set: [pipefail]
    preconditions:
      - sh: command -v stat >/dev/null 2>&1
        msg: "stat not found"
      - sh: command -v mount >/dev/null 2>&1
        msg: "mount not found"
    cmds:
      - stat -fc %T /sys/fs/cgroup
      - mount | grep -E 'cgroup2?|/sys/fs/cgroup'

  proc:cgroup:proc:
    desc: Show cgroup membership for PID
    summary: "task -g proc:cgroup:proc [PID=1]"
    platforms: [linux]
    preconditions:
      - sh: test -r /proc/{{.PID}}/cgroup
        msg: "/proc/{{.PID}}/cgroup not readable"
      - sh: command -v systemd-cgls >/dev/null 2>&1
        msg: "systemd-cgls not found (systemd required)"
    cmds:
      - cat /proc/{{.PID}}/cgroup
      - systemd-cgls

  proc:cgroup:v2:controllers:
    desc: Show cgroup v2 controllers
    summary: "task -g proc:cgroup:v2:controllers"
    platforms: [linux]
    preconditions:
      - sh: test -r /sys/fs/cgroup/cgroup.controllers
        msg: "/sys/fs/cgroup/cgroup.controllers not readable"
    cmds:
      - cat /sys/fs/cgroup/cgroup.controllers
      - cat /sys/fs/cgroup/cgroup.subtree_control

  proc:cgroup:v2:stats:
    desc: Show cgroup v2 limits for CGROUP_PATH
    summary: "task -g proc:cgroup:v2:stats [CGROUP_PATH=system.slice]"
    platforms: [linux]
    requires:
      vars: [CGROUP_PATH]
    preconditions:
      - sh: test -r /sys/fs/cgroup/{{.CGROUP_PATH}}/cpu.max
        msg: "/sys/fs/cgroup/{{.CGROUP_PATH}}/cpu.max not readable"
      - sh: test -r /sys/fs/cgroup/{{.CGROUP_PATH}}/memory.max
        msg: "/sys/fs/cgroup/{{.CGROUP_PATH}}/memory.max not readable"
      - sh: test -r /sys/fs/cgroup/{{.CGROUP_PATH}}/io.max
        msg: "/sys/fs/cgroup/{{.CGROUP_PATH}}/io.max not readable"
    cmds:
      - cat /sys/fs/cgroup/{{.CGROUP_PATH}}/cpu.max
      - cat /sys/fs/cgroup/{{.CGROUP_PATH}}/memory.max
      - cat /sys/fs/cgroup/{{.CGROUP_PATH}}/io.max

```


</details>






### Taskfile.ns.yml



<details>
<summary>Taskfile.ns.yml</summary>

```yaml
---
version: "3"

vars:
  # PID: 目标进程 PID
  PID: '{{.PID | default "1"}}'
  # SHELL: 进入 namespace 后使用的 shell
  SHELL: '{{.SHELL | default "bash"}}'

tasks:
  proc:ns:summary:
    desc: Namespace summary (lsns by PID + types)
    summary: "task -g proc:ns:summary [PID=1]"
    platforms: [linux]
    preconditions:
      - sh: command -v lsns >/dev/null 2>&1
        msg: "lsns not found (install: util-linux)"
    cmds:
      - lsns -t pid,net,uts,ipc,mnt,user,cgroup
      - lsns -p {{.PID}}

  proc:ns:proc:
    desc: Namespace links under /proc/<PID>/ns
    summary: "task -g proc:ns:proc [PID=1]"
    platforms: [linux]
    preconditions:
      - sh: test -r /proc/{{.PID}}/ns
        msg: "/proc/{{.PID}}/ns not readable"
    cmds:
      - ls -l /proc/{{.PID}}/ns
      - readlink /proc/{{.PID}}/ns/net

  proc:ns:enter:
    desc: Enter target namespaces (nsenter)
    summary: "task -g proc:ns:enter PID=1 [SHELL=bash]"
    platforms: [linux]
    interactive: true
    requires:
      vars: [PID]
    preconditions:
      - sh: command -v nsenter >/dev/null 2>&1
        msg: "nsenter not found (install: util-linux)"
    cmds:
      - nsenter -t {{.PID}} -m -u -i -n -p -- {{.SHELL}}

  proc:ns:unshare:
    desc: Create new namespaces (unshare + mount /proc)
    summary: "task -g proc:ns:unshare [SHELL=bash]"
    platforms: [linux]
    interactive: true
    preconditions:
      - sh: command -v unshare >/dev/null 2>&1
        msg: "unshare not found (install: util-linux)"
    cmds:
      - unshare -p -f --mount-proc {{.SHELL}}

```


</details>




### Taskfile.process.yml

<details>
<summary>Taskfile.process.yml</summary>

```yaml
---
version: "3"

vars:
  # LIMIT: 输出行数上限
  LIMIT: '{{.LIMIT | default "200"}}'
  # PID: 目标进程 PID
  PID: '{{.PID | default "1"}}'

tasks:
  proc:ps:zombie:
    desc: List zombie processes (state=Z)
    summary: "task -g proc:ps:zombie"
    platforms: [linux]
    set: [pipefail]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
      - sh: command -v awk >/dev/null 2>&1
        msg: "awk not found"
    cmds:
      # -e: all processes; -o: custom columns (pid,ppid,state,stat,cmd)
      - ps -eo pid,ppid,state,stat,cmd | awk '$3 ~ /Z/ || $4 ~ /Z/ {print}'
      # -l: long format (includes state); filter Z in S column
      - ps -el | awk '$2 ~ /Z/ {print}'

  proc:ps:orphan:
    desc: List processes with PPID=1 (possible orphans)
    summary: "task -g proc:ps:orphan [LIMIT=200]"
    platforms: [linux]
    set: [pipefail]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
      - sh: command -v awk >/dev/null 2>&1
        msg: "awk not found"
    cmds:
      # -e: all processes; -o: custom columns (pid,ppid,cmd)
      - ps -eo pid,ppid,cmd | awk '$2==1 {print}'
      # --forest: show process tree; LIMIT limits output size
      - ps -eo pid,ppid,cmd --forest | head -n {{.LIMIT}}

  proc:ps:tree:
    desc: Process tree (ps forest + pstree)
    summary: "task -g proc:ps:tree [LIMIT=200]"
    platforms: [linux]
    set: [pipefail]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
      - sh: command -v pstree >/dev/null 2>&1
        msg: "pstree not found (install: psmisc)"
    cmds:
      # --forest: show process tree; LIMIT limits output size
      - ps -eo pid,ppid,cmd --forest | head -n {{.LIMIT}}
      # -p: show PIDs in the tree
      - pstree -p

  proc:ps:parent:
    desc: Show parent process for PID
    summary: "task -g proc:ps:parent PID=1"
    platforms: [linux]
    requires:
      vars: [PID]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
    cmds:
      # -p: select PID; -o: custom columns (pid,ppid,state,stat,cmd)
      - ps -o pid,ppid,state,stat,cmd -p {{.PID}}
      # get PPID of PID, then show parent process details
      - ps -o pid,ppid,state,stat,cmd -p $(ps -o ppid= -p {{.PID}} | tr -d ' ')

  proc:ps:state:sort:
    desc: List processes sorted by state
    summary: "task -g proc:ps:state:sort"
    platforms: [linux]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
    cmds:
      # -e: all processes; -o: custom columns (state,pid,comm); --sort=state groups by state
      - ps -e -o state,pid,comm --sort=state
      # stat includes flags (e.g., R+, Ss); --sort=stat groups by full STAT
      - ps -e -o stat,pid,comm --sort=stat

  proc:ps:state:group:
    desc: Group processes by state (sectioned output)
    summary: "task -g proc:ps:state:group"
    platforms: [linux]
    set: [pipefail]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
      - sh: command -v awk >/dev/null 2>&1
        msg: "awk not found"
    cmds:
      # -o state=,pid=,comm=: omit headers; awk groups by state
      - ps -e -o state=,pid=,comm= | awk '{s=$1; pid=$2; $1=$2=""; sub(/^  */,""); bucket[s]=bucket[s] sprintf("  %-7s %s\n", pid, $0)} END{n=split("R S D T Z X I", order, " "); for(i=1;i<=n;i++){s=order[i]; if(bucket[s]!=""){print "== " s " =="; printf "%s", bucket[s]; print ""}} for(s in bucket){found=0; for(i=1;i<=n;i++) if(s==order[i]) found=1; if(!found){print "== " s " =="; printf "%s\n", bucket[s]}}}'

  proc:ps:state:count:
    desc: Count processes by state
    summary: "task -g proc:ps:state:count"
    platforms: [linux]
    set: [pipefail]
    preconditions:
      - sh: command -v ps >/dev/null 2>&1
        msg: "ps not found"
      - sh: command -v sort >/dev/null 2>&1
        msg: "sort not found"
      - sh: command -v uniq >/dev/null 2>&1
        msg: "uniq not found"
    cmds:
      # state= removes header; sort|uniq -c counts; sort -nr shows top states first
      - ps -e -o state= | sort | uniq -c | sort -nr

```


</details>
