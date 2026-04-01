---
name: jq
description: JSON processor for filtering, transforming, and extracting data
---
# jq

JSON processor for filtering, transforming, and extracting data.

> 定位：jq 是“JSON 瑞士军刀”（Swiss knife）——**零接入成本、强组合性、确定性输出、适合管道/CI/排查**。
> AI 时代的正确用法：让 AI 生成初稿，但你要用本 skill 的**模式库 + 用例测试 + 坑位/最佳实践**快速验收与微调。

---

## Quick Reference
```sh
jq '.field' file.json                      # Extract field
jq '.[] | .name' file.json                 # Extract from array
jq -r '.email' file.json                   # Raw output (unquoted strings)
jq -c '.items[] | {id, name}' file.json    # Compact, stream-friendly output
jq -s 'add' file1.json file2.json          # Slurp and merge
jq '.[] | select(.active)' file.json       # Filter elements
jq '.[] | {id, name}' file.json            # Pick fields
jq -S '.' file.json                        # Sort keys for stable output
```

---

## Key Flags
| Flag | Purpose |
|------|----------|
| `-r` | Output strings without quotes (raw mode) |
| `-R` | Read input as plain text lines, not JSON |
| `-s` | Slurp: read all inputs into single array |
| `-n` | Start with null input (no file reading) |
| `-c` | Compact output (single line) |
| `-e` | Set exit status based on output |
| `-f FILE` | Read jq program from file |
| `--arg x v` | Bind `$x` to string value `v` |
| `--argjson x j` | Bind `$x` to JSON value `j` |
| `--slurpfile x f.json` | Bind `$x` to array of JSON read from file (slurped) |
| `--rawfile x f.txt` | Bind `$x` to raw text content of file |
| `--sort-keys` / `-S` | Sort object keys |

---

## Best Practices（最佳实践）
### 1) 默认用“稳定、可验收”的输出
- **日志/管道优先用** `-c`：一行一个 JSON，便于 `grep` / `xargs` / 机器处理。
- **需要稳定 diff/缓存命中**：加 `-S`（key 排序）+ 明确排序：`sort_by(...)`。
- **有“判断是否成功”的语义**：用 `-e` 配合 `select(...)` 或断言（见模式 #23/#24），让 CI 能失败。

### 2) 敏感数据：只“投影白名单”，不要“黑名单删除”
- **推荐**：`{id: .id, name: .name}`（白名单投影）
- **不推荐**：`del(.password,.token)`（黑名单易漏字段、易透传）

### 3) 参数传入：永远用 `--arg / --argjson`，别拼接字符串
- 避免 shell quoting 地狱与注入风险：
    - `--arg role "admin"`（字符串）
    - `--argjson ids '[1,2,3]'`（JSON 值）

### 4) 空值与缺字段：显式策略（丢弃 / 默认 / 兼容）
- 缺字段容错：`.foo?`
- 默认值：`.foo // "UNKNOWN"`
- 类型变动：用 `type` 做保护（模式 #17）

### 5) 性能：别盲目 slurp
- 大文件/流式日志：避免 `-s`（会把所有输入读入内存）
- 需要流式处理：优先写成 `.items[] | ...` + `-c`，一条一条吐。
- 只有在确实需要“全量聚合/分组”时才用 `-s` 或 `group_by`。

### 6) 团队复用：把复杂 filter 放进 `.jq` 文件
- `jq -f transform.jq input.json`
- filter 文件里写注释 + 用例 + 版本约束，避免“咒语化”失控。

---

## Gotchas（坑位笔记）
1) **shell quoting（最常见坑）**
- Bash/Zsh 中：尽量用单引号包 jq 程序：`jq '.a | .b'`
- 程序里需要单引号/变量时：别硬拼，改用 `--arg`/`--argjson`
2) **`--argjson` vs `--arg`**
- `--argjson` 绑定的是 JSON 值；`--arg` 永远是字符串（即使你传 `{"a":1}` 也只是字符串）
3) **`group_by` 必须先排序**
- `group_by(.k)` 之前要 `sort_by(.k)`，否则结果不正确或不稳定
4) **数组/对象混用导致报错**
- `.items[]` 但 `.items` 可能是对象/空值，会报错；用 `.items? // [] | .[]`
5) **`-r` 会改变输出类型**
- `-r` 输出纯文本，后续管道如果期待 JSON 会炸；一般只在最终输出字段时用
6) **空输出 vs null**
- `select(...)` 过滤掉会“无输出”；`.foo?` 缺字段会输出 `null`（除非再 `select(.!=null)`）
7) **`unique_by` 与 `group_by` 的排序前置**
- `unique_by(.k)` 通常也建议 `sort_by(.k)` 让行为稳定

---

## Pattern Library（模式库：模板 + 最小测试）
> 每个模式都提供：用途、模板、最小输入/期望输出（可直接复制粘贴运行）。
> 说明：测试用例使用 heredoc，便于本地快速验证；输出示例一般使用 `-c` 以稳定对比。

### 1) 从数组中“抽字段白名单”并组装新数组（脱敏首选）
**模板**
```sh
jq '[.[] | {id: .id, name: .name}]'
```
**最小测试**
```sh
cat <<'JSON' | jq -c '[.[] | {id: .id, name: .name}]'
[
  {"id":1,"name":"a","token":"SECRET"},
  {"id":2,"name":"b","password":"HIDDEN"}
]
JSON
# => [{"id":1,"name":"a"},{"id":2,"name":"b"}]
```

### 2) 过滤元素（select）
**模板**
```sh
jq -c '[.[] | select(.active == true)]'
```
**最小测试**
```sh
cat <<'JSON' | jq -c '[.[] | select(.active == true)]'
[
  {"id":1,"active":true},
  {"id":2,"active":false}
]
JSON
# => [{"id":1,"active":true}]
```

### 3) 重命名字段（映射构造）
**模板**
```sh
jq -c '. | {userId: .id, userName: .name}'
```
**最小测试**
```sh
cat <<'JSON' | jq -c '. | {userId: .id, userName: .name}'
{"id":7,"name":"lu"}
JSON
# => {"userId":7,"userName":"lu"}
```

### 4) 安全访问（缺字段不报错）+ 默认值
**模板**
```sh
jq -c '{city: (.user.address.city? // "UNKNOWN")}'
```
**最小测试**
```sh
cat <<'JSON' | jq -c '{city: (.user.address.city? // "UNKNOWN")}'
{"user":{"address":{}}}
JSON
# => {"city":"UNKNOWN"}
```

### 5) 删除字段（黑名单删除：仅用于“确认字段全集已知”的场景）
**模板**
```sh
jq -c 'del(.token, .password)'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'del(.token, .password)'
{"id":1,"token":"SECRET","password":"HIDDEN","name":"a"}
JSON
# => {"id":1,"name":"a"}
```

### 6) 深层删除敏感字段（递归 walk：高级但实用）
**模板**
```sh
jq -c 'walk(if type=="object" then del(.token?, .password?) else . end)'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'walk(if type=="object" then del(.token?, .password?) else . end)'
{"user":{"token":"SECRET","profile":{"password":"HIDDEN","name":"a"}}}
JSON
# => {"user":{"profile":{"name":"a"}}}
```

### 7) 扁平化：嵌套数组/对象 -> 扁平条目
**模板**
```sh
jq -c '.orders[] | {orderId: .id, sku: .item.sku, qty: .item.qty}'
```
**最小测试**
```sh
cat <<'JSON' | jq -c '.orders[] | {orderId: .id, sku: .item.sku, qty: .item.qty}'
{
  "orders":[
    {"id":1,"item":{"sku":"A","qty":2}},
    {"id":2,"item":{"sku":"B","qty":1}}
  ]
}
JSON
# => {"orderId":1,"sku":"A","qty":2}
# => {"orderId":2,"sku":"B","qty":1}
```

### 8) 把“对象 map”转成 entries（便于过滤/排序）
**模板**
```sh
jq -c 'to_entries | map(select(.value >= 2))'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'to_entries | map(select(.value >= 2))'
{"a":1,"b":2,"c":3}
JSON
# => [{"key":"b","value":2},{"key":"c","value":3}]
```

### 9) entries 转回对象（from_entries）
**模板**
```sh
jq -c 'to_entries | map(select(.key!="token")) | from_entries'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'to_entries | map(select(.key!="token")) | from_entries'
{"id":1,"token":"SECRET","name":"a"}
JSON
# => {"id":1,"name":"a"}
```

### 10) 合并对象（后者覆盖前者）
**模板**
```sh
jq -c '.a * .b'
```
**最小测试**
```sh
cat <<'JSON' | jq -c '.a * .b'
{"a":{"x":1,"y":1},"b":{"y":2,"z":3}}
JSON
# => {"x":1,"y":2,"z":3}
```

### 11) 合并多个 JSON 输入（slurp + add）
**模板**
```sh
jq -s 'add'
```
**最小测试**
```sh
cat <<'JSON' | jq -c -s 'add'
{"a":1}
{"b":2}
JSON
# => {"a":1,"b":2}
```

### 12) 按字段排序（稳定输出）
**模板**
```sh
jq -c 'sort_by(.score)'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'sort_by(.score)'
[{"id":1,"score":9},{"id":2,"score":3}]
JSON
# => [{"id":2,"score":3},{"id":1,"score":9}]
```

### 13) 去重（unique_by）——推荐先 sort_by
**模板**
```sh
jq -c 'sort_by(.id) | unique_by(.id)'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'sort_by(.id) | unique_by(.id)'
[{"id":2},{"id":1},{"id":2}]
JSON
# => [{"id":1},{"id":2}]
```

### 14) 分组聚合计数（group_by：先排序）
**模板**
```sh
jq -c 'sort_by(.type) | group_by(.type) | map({type: .[0].type, count: length})'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'sort_by(.type) | group_by(.type) | map({type: .[0].type, count: length})'
[{"type":"a"},{"type":"b"},{"type":"a"}]
JSON
# => [{"type":"a","count":2},{"type":"b","count":1}]
```

### 15) 分组求和（sum）
**模板**
```sh
jq -c 'sort_by(.k) | group_by(.k) | map({k: .[0].k, total: (map(.v) | add)})'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'sort_by(.k) | group_by(.k) | map({k: .[0].k, total: (map(.v) | add)})'
[{"k":"x","v":2},{"k":"x","v":3},{"k":"y","v":1}]
JSON
# => [{"k":"x","total":5},{"k":"y","total":1}]
```

### 16) 构建索引（数组 -> 以 id 为 key 的对象）
**模板**
```sh
jq -c 'map({(.id|tostring): .}) | add'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'map({(.id|tostring): .}) | add'
[{"id":1,"name":"a"},{"id":2,"name":"b"}]
JSON
# => {"1":{"id":1,"name":"a"},"2":{"id":2,"name":"b"}}
```

### 17) 类型保护：数组/对象混用时不炸
**模板**
```sh
jq -c 'if type=="array" then map(.id) elif type=="object" then [.id] else [] end'
```
**最小测试**
```sh
cat <<'JSON' | jq -c 'if type=="array" then map(.id) elif type=="object" then [.id] else [] end'
{"id":9}
JSON
# => [9]
```

### 18) 输出 TSV（@tsv）——适合管道/表格导入
**模板**
```sh
jq -r '.[] | [.id, .name] | @tsv'
```
**最小测试**
```sh
cat <<'JSON' | jq -r '.[] | [.id, .name] | @tsv'
[{"id":1,"name":"a"},{"id":2,"name":"b"}]
JSON
# => 1	a
# => 2	b
```

### 19) 输出 CSV（@csv）——注意字符串会自动加引号
**模板**
```sh
jq -r '.[] | [.id, .name] | @csv'
```
**最小测试**
```sh
cat <<'JSON' | jq -r '.[] | [.id, .name] | @csv'
[{"id":1,"name":"a"},{"id":2,"name":"b"}]
JSON
# => 1,"a"
# => 2,"b"
```

### 20) 使用变量过滤（--arg）
**模板**
```sh
jq --arg role "admin" -c '[.users[] | select(.role == $role)]'
```
**最小测试**
```sh
cat <<'JSON' | jq --arg role "admin" -c '[.users[] | select(.role == $role)]'
{"users":[{"id":1,"role":"admin"},{"id":2,"role":"user"}]}
JSON
# => [{"id":1,"role":"admin"}]
```

### 21) JSON 变量（--argjson）：传数组/对象/数字等
**模板**
```sh
jq --argjson ids '[1,3]' -c '[.[] | select(.id as $i | ($ids | index($i)) != null)]'
```
**最小测试**
```sh
cat <<'JSON' | jq --argjson ids '[1,3]' -c '[.[] | select(.id as $i | ($ids | index($i)) != null)]'
[{"id":1},{"id":2},{"id":3}]
JSON
# => [{"id":1},{"id":3}]
```

### 22) 读文本行（-R）并解析每行 JSON（日志常见）
**模板**
```sh
jq -R -c 'fromjson? | select(. != null) | {id: .id}'
```
**最小测试**
```sh
cat <<'TXT' | jq -R -c 'fromjson? | select(. != null) | {id: .id}'
{"id":1,"x":1}
not-json
{"id":2,"x":2}
TXT
# => {"id":1}
# => {"id":2}
```

### 23) 断言/校验：缺字段就让命令失败（CI 友好）
**模板**
```sh
jq -e 'has("id") and has("name")'
```
**最小测试**
```sh
cat <<'JSON' | jq -e 'has("id") and has("name")' >/dev/null; echo $?
{"id":1,"name":"a"}
JSON
# => 0

cat <<'JSON' | jq -e 'has("id") and has("name")' >/dev/null; echo $?
{"id":1}
JSON
# => 1
```

### 24) 只输出存在的结果，否则退出失败（select + -e）
**模板**
```sh
jq -e '.[] | select(.active==true) | .id'
```
**最小测试**
```sh
cat <<'JSON' | jq -e '.[] | select(.active==true) | .id' >/dev/null; echo $?
[{"id":1,"active":false}]
JSON
# => 1

cat <<'JSON' | jq -e '.[] | select(.active==true) | .id' >/dev/null; echo $?
[{"id":1,"active":true}]
JSON
# => 0
```

---

## Recommended Shell Wrapper（推荐的管道写法）
> 让脚本更“可失败、可追踪、可复用”。

```sh
set -euo pipefail

# 1) 明确输入来源（文件/STDIN）
# 2) 明确输出格式（-c / -r）
# 3) 明确失败语义（-e）
jq -c -e '[.[] | {id: .id, name: .name}]' input.json > output.json
```

---

## AI Prompt Template（可复制给 AI）
> 目标：让 AI 生成 jq 时自带“策略 + 用例 + 可验收输出”。

```text
你是 jq 专家。请基于下面输入样例与期望输出，给出 jq 命令：
- 约束：jq 版本 jq-1.8.1；输出必须是 JSON（除非我说明要 -r/@tsv/@csv）
- 空值/缺字段策略：请明确（丢弃 / 默认值 / 输出 null）
- 安全：仅输出白名单字段，禁止透传敏感字段（如 token/password/secret 等）
- 请同时给出最小测试：输入、命令、期望输出（便于 diff 验收）

输入样例：
...

期望输出样例：
...
```
