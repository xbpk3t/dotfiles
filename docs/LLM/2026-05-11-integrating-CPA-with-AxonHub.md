---
title: AxonHub 接入 CPA：Codex OAuth 账号池与 Tailnet 内网部署实践
date: 2026-05-11
isOriginal: true
category: workflow-issues
module: cntr
problem_type: workflow_issue
component: tooling
severity: medium
applies_when:
  - Nix + Home Manager 环境里需要给 Docker Compose 栈注入运行时变量
  - 服务只允许通过 tailnet 访问，不希望暴露到公网
  - 容器健康检查正常，但远程访问仍然失败
  - user-level sops-nix secret 可能晚于登录 shell 可用
tags:
  - LLM
  - LLM路由
  - CPA
  - AxonHub
  - Tailscale
---

:::tip[TLDR]

这次改造的核心是：不再让 AxonHub 直接管理 Codex OAuth / auth.json，而是引入 CPA 作为账号池适配层。

最终架构是：

```
Client / Internal Service → AxonHub → CPA → OpenAI / Codex OAuth Accounts
```

AxonHub 继续负责统一入口、鉴权、模型映射和日志；CPA 负责 OAuth 账号池、auth.json、账号轮询、token refresh 和健康检查。

CPA 不暴露公网，只监听 Tailscale IPv4，作为 tailnet 内部服务被 AxonHub 访问。


---

> ***这里要注意我们的使用场景：***

- 已有 AxonHub 作为统一 LLM 网关，需要管理多个 Codex / OpenAI OAuth 账号
- 需要账号池化、健康检查、轮询调度和 quota 观测
- 对内网安全边界有要求，不希望 OAuth 凭据暴露到公网

如果只是单账号、低频调用，AxonHub 直接接 Codex Provider 也可以满足基本需求；但一旦涉及多账号管理或内网安全约束，CPA 会是更清晰的职责拆分。


:::

## 背景：AxonHub 直连 Codex 的局限


之前只是用 AxonHub 来作为唯一的 LLM 网关。但随着使用深入，发现：

> AxonHub 更适合做统一网关、模型路由、鉴权和日志；但不适合直接承担 Codex OAuth 多账号池、auth.json 管理、账号健康检查和轮询调度。因此引入 CPA 作为账号池适配层，把职责拆清楚。


```text
1. 背景：最初尝试 AxonHub 直接接 Codex auth.json
2. 问题：单账号可用，但多账号管理和 Fetch Models 流程存在限制
3. 目标：需要多账号池化、内网部署、统一出口、低延迟、可控重试
4. 方案：引入 CPA，AxonHub 选择 OpenAI provider 指向 CPA
```


最初的方案是直接在 AxonHub 中添加 Codex Provider，并通过 Codex CLI 生成的 `auth.json` 导入凭据。这个方案在单账号场景下可以工作：手动填入模型后，实际请求能够正常转发。

但在使用过程中发现，AxonHub 直连 Codex 更适合简单场景，在多账号池化、批量管理、账号轮询、健康检查等方面并不是最佳职责边界。

并且还遇到了bug

[[Bug/错误]: 使用 codex + auth.json 时无法 featch models · Issue #1636 · looplj/axonhub](https://github.com/looplj/axonhub/issues/1636#event-25383315997)

具体来说：

在 Codex + `auth.json` 模式下，AxonHub 的 `Fetch Models` 流程会尝试请求：

```text
https://chatgpt.com/backend-api/codex/models
```

该接口返回 `400 Bad Request`，导致自动拉取模型失败。虽然手动填入模型后实际调用可用，但这说明 AxonHub 的 Codex Provider 在 `auth.json` 新建 Channel 流程里存在兼容性问题。

因此，我们没有继续让 AxonHub 直接承担 Codex OAuth 账号管理，而是引入 CPA 作为中间账号池服务。

这里的 CPA 是一个 OpenAI-compatible 的账号池服务：对外暴露 `/v1` 接口，对内负责 OAuth 账号管理、token refresh 和账号轮询调度。


:::caution


并且想了一下，无论如何，AxonHub也不可能把对于 `OpenAI`这部分的体验优化到类似CPA这种程度

最明显的，不可能有对于 5h 和 week 的 token limit 展示


:::



## 简易设计


最终采用的架构是：

```text
Client / Internal Service
        ↓
     AxonHub
        ↓
      CPA
        ↓
OpenAI / Codex OAuth Accounts
```

在这个方案中，AxonHub 不再直接选择 Codex Provider，而是选择 **OpenAI Provider**，并将 Base URL 指向 CPA 暴露的 OpenAI-compatible API。

也就是说，对 AxonHub 来说，CPA 是一个标准的 OpenAI-compatible upstream；而 Codex OAuth、`auth.json`、账号池、轮询、token refresh 等逻辑都由 CPA 负责。


### 职责划分

这次调整之后，两个组件的职责更加清晰。

AxonHub 负责：

```text
统一 API 入口
API Key 管理
模型映射
请求日志
项目隔离
网关层路由
对外 OpenAI-compatible 接口
```

CPA 负责：

```text
Codex / OpenAI OAuth 账号管理
auth.json 管理
多账号池化
账号轮询
token refresh
账号健康检查
额度消耗观测
```

这种分层避免了 AxonHub 直接处理 Codex OAuth 的复杂度，也绕开了 AxonHub Codex Provider 当前在 Fetch Models 流程中的兼容性问题。

### 网络与安全

CPA 不直接暴露公网，只作为内部服务使用。

当前访问路径是：

```text
公网 / Tailscale Client
        ↓
     AxonHub
        ↓
localhost / Tailscale / 内网
        ↓
       CPA
```

这样做有几个好处：

```text
CPA 不暴露公网攻击面
OAuth 凭据只留在内部服务中
AxonHub 仍然作为唯一统一入口
内网访问延迟低
部署和排障更清晰
```

如果 AxonHub 和 CPA 在同一台机器上，可以直接使用：

```text
http://127.0.0.1:8317/v1
```

如果 AxonHub 在容器中，则需要使用 Docker network、`host.docker.internal` 或 Tailscale IP / MagicDNS 访问 CPA。

### Retry 与路由策略

这套架构中需要重点避免“双层重试”。

因为 AxonHub 本身可能有 retry / fallback，CPA 内部也会做账号轮询和失败切换。如果两层都启用较强的 retry，可能导致一次用户请求被打到多个 Codex 账号，带来额外延迟和不可控的 quota 消耗。

因此当前策略是：

```text
CPA 负责账号池内部调度
AxonHub 尽量不对 CPA Channel 做额外 retry
CPA 限制单次请求最多尝试的账号数量
开启 session affinity，减少同一会话频繁切换账号
```

推荐的 CPA 侧保守配置方向是：

```yaml
request-retry: 0
max-retry-credentials: 1
max-retry-interval: 0

routing:
  strategy: "round-robin"
  session-affinity: true
  session-affinity-ttl: "1h"

streaming:
  bootstrap-retries: 0
```

后续如果需要提高可用性，可以将 `max-retry-credentials` 调整为 `2`，但不建议让单次请求打穿整个账号池。


## tailscale内网访问CPA

两种方案的本质区别在于访问语义——先确定你要什么访问形态，再选工具：

| 方案 | 访问方式 | 优点 | 缺点 |
|---|---|---|---|
| 直接绑定 Tailscale IPv4 | `http://100.x.x.x:port` | 简单直观、符合现有 compose 暴露方式 | 需要注入 `TAILSCALE_IPV4` 环境变量 |
| Tailscale Serve | `https://<machine>.<tailnet>.ts.net` | 不依赖固定 IP，自带 HTTPS / MagicDNS | 需额外维护 serve 配置，访问形态变化大 |

这里选择方案 1，因为当前需求只是让 CPA / keeper 这类内部服务在 tailnet 内以明确端口访问。直接绑定 Tailscale IPv4 对现有 Docker Compose 结构侵入更小：

```yaml
ports:
  - "${TAILSCALE_IPV4:?TAILSCALE_IPV4 is required}:8080:8080"
```

当前 `compose.yml` 里本来就用 `ports` 暴露服务，只需把 host bind 地址从 `127.0.0.1` 改成变量即可，整体结构不变。而 Tailscale Serve 则需要额外维护一套 systemd service：

```nix
systemd.services.tailscale-serve-cpa-usage-keeper = {
  description = "Expose cpa-usage-keeper to tailnet via Tailscale Serve";

  after = [
    "tailscaled.service"
    "docker.service"
  ];

  wants = [
    "tailscaled.service"
    "docker.service"
  ];

  wantedBy = [ "multi-user.target" ];

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;

    ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --https=443 http://127.0.0.1:8080";
    ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=443 off";
  };
};
```

这还没算上 serve 配置持久化、多服务 path 分配、path prefix 兼容性等问题。相比之下，方案 1 只需在 compose 里改一行变量。

启动 compose 前在 `home/base/core/cntr.nix` 中注入 `TAILSCALE_IPV4`，即可做到：

- 不把 Tailscale IP 写死在 `compose.yml`
- 服务只监听 Tailscale IPv4，不暴露公网
- 保留 `100.x:port` 的直接访问方式
- 其他需要 tailnet 内暴露的服务可复用同一变量（`”${TAILSCALE_IPV4:?TAILSCALE_IPV4 is required}:xxxx:xxxx”`）

## 结论

目前 CPA + AxonHub 方案已经上线，并验证可用。

上线后带来的收益：

- 避免 AxonHub 直接接 Codex auth.json 的 Fetch Models 问题
- 支持多个 Codex / OpenAI OAuth 账号统一池化
- AxonHub 侧只需维护一个 OpenAI-compatible upstream
- CPA 不暴露公网，安全边界更清晰
- 账号管理、网关路由、模型映射职责分离
- 后续扩展多个账号或多个池子更方便

本次改造的核心不是简单增加一层代理，而是重新划分职责：**AxonHub 做网关，CPA 做账号池**。AxonHub 继续承担统一入口、鉴权、模型映射和日志能力；CPA 则专注于 Codex / OpenAI OAuth 账号的管理、轮询和健康维护。

对于个人或内部自用场景，这个架构比直接在 AxonHub 中添加多个 Codex Channel 更清晰，也更容易扩展和维护。后续需要重点关注的是账号健康状态、retry 行为、quota 消耗和 CPA 版本兼容性。

---


:::tip[收尾]

上面这套 `CPA`+`CPA-usage-keeper` 服务跑通之后，需要把 CPA重新挂回AxonHub


因为本身就是内网打通，所以在 AxonHub 里配置如下：

```yaml
- Provider: OpenAI
- Base URL: http://cpa:8317/v1
- API Key: `__CPA_API_KEY__`
```

但是在此之前需要把OpenAI账号什么都刷入CPA，否则在AxonHub里 fetch models时，会成功刷新，但是拿不到models。

关于“把账号刷入CPA”，这里加条说明：

无非两种方案：

- OAuth登录然后把 `callback URL`复制回来
- 直接把 `auth.json` 贴进去

~~基于“如果有多个账号的话，无论选择什么方案，其实都要完整走完登录流程”这条基本原则~~

~~那么可以得出结论：从这点来说二者没啥区别。还是直接 OAuth会更方便。~~

:::


## 使用 codex-auth 代替CPA [2026-05-12] {#replace-CPA-with-codex-auth}

:::tip[TLDR]

在收尾本issue过程中，发现了 [Loongphy/codex-auth](https://github.com/loongphy/codex-auth)

其实本身就可以完美替代CPA来实现我的核心需求：查看OpenAI账号的 5h/week limit（具体查看 [背景：AxonHub 直连 Codex 的局限](#背景axonhub-直连-codex-的局限) 这部分）

简单来说，我日常最多使用 2-4个 `OpenAI Team/Plus`账号，搭配其他provider，足够我用了，直接把账号挂到AxonHub里，然后用 `codex-auth`查看 `limit usage`即可，其实并不需要CPA


---

顺手还给 `llm-agents.nix` 提了`codex-auth`的PR

[codex-auth: init at 0.2.8 by xbpk3t · Pull Request #4806 · numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix/pull/4806)

:::




### 新架构
```
Client / Internal Service → AxonHub → Codex OAuth Accounts (由 codex-auth 管理)
```

- AxonHub 继续作为唯一对外统一入口（OpenAI-compatible）。
- **codex-auth** 负责所有账号的登录、导入、切换、额度监控和 auth 文件管理。
- AxonHub 的 Codex Provider 直接使用 codex-auth 维护的 auth.json / sessions。

### 切换原因
1. **足够轻量**：仅 4 个 Team 账号，codex-auth 已能满足核心需求。
2. **额度监控满足**：`codex-auth list` 可直接集中展示所有账号的 **5H Usage + Weekly Usage**，无需切换账号查看。
3. **简化架构**：去掉 CPA 中间层，减少部署维护、Tailnet 内网服务和潜在双层重试问题。
4. **安全边界更清晰**：OAuth 凭据仅存在于 AxonHub 所在环境，无额外服务暴露。
5. **避免已知兼容性问题**：绕过之前 AxonHub + CPA 集成中的部分复杂度和职责重叠。

### 使用方式
- 使用 `codex-auth` 进行账号导入、alias 设置和日常管理（推荐开启 local-only 模式：`codex-auth config api disable`）。
- AxonHub 配置中直接指向 codex-auth 维护的 auth 文件或 sessions 路径。
- 需要切换账号时，通过 `codex-auth switch` 快速操作。

### 收益
- 整体架构大幅简化，维护成本降低。
- 本地 CLI 操作体验更好，符合个人 workflow。
- 减少一层网络跳转，理论延迟更低。
- 攻击面缩小。
