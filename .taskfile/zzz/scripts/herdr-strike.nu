#!/usr/bin/env nu
# herdr-strike.nu — 通过 herdr 批量深潜学习
#
# 用法:
#   nu herdr-strike.nu <md文件> <"h2标题1,h2标题2,...">
#
# 流程:
#   1. ^mq 按指定 h2 标题提取每节内容（展示给你看, 供你在 pane 里粘贴）
#   2. 为每个 topic 建 herdr workspace + 在 docs 项目内启动 claude（自动拿 sid）
#   3. 你在 herdr TUI 里切各 pane 自由深潜
#   4. 聊完输 DONE → 脚本 wait 到后自动触发 uu / conclusion / ccx export, 并关 pane
#
# 前置条件:
#   - herdr server 在运行
#   - mq 已安装

let DONE_MARKER    = 'DONE'
let EXPORT_DIR     = '/tmp/herdr-strike-export'
let PROJECT_DIR    = '/Users/luck/Desktop/docs'
let UU_PROMPT_PATH = ($env.HOME | path join 'Desktop/dotfiles/home/base/AI/skills/zzz/references/analysis/uu.md')
let CONCLUSION_PROMPT_PATH = ($env.HOME | path join 'Desktop/dotfiles/home/base/AI/skills/zzz/references/conclusion.md')

# ─── 辅助：用 ^mq 提取指定 h2 的 section 内容 ───
def get-sections [
    md_file: string
    topics: list<string>
]: nothing -> list<record<topic: string content: string>> {
    $topics | each {|name|
        let trimmed = ($name | str trim)
        # 拼 mq query: section::section("标题")
        # 注意: 不能用 $"..." 插值, 因为 () 会被当插值符; 用 + 拼接
        let dq = (char double_quote)
        let query = ("section::section(" + $dq + $trimmed + $dq + ")")
        let res = (^mq -A $query $md_file o+e>| complete)
        if $res.exit_code != 0 {
            null
        } else {
            let content = ($res.stdout | str trim)
            if ($content | is-empty) {
                null
            } else {
                {topic: $trimmed, content: $content}
            }
        }
    } | compact
}

# ─── 辅助：为单个 topic 创建 workspace + 启动 claude + 等 sid ───
def create-topic-pane [
    topic: string
]: nothing -> record<topic: string pane_id: string sid: string status: string> {
    # 1. 建 workspace（cwd 必须指向 docs 项目, 否则 claude 要交互确认）
    #    create 返回值里直接含 workspace_id 和 root_pane.pane_id, 省两步查询
    let created = (herdr workspace create --cwd $PROJECT_DIR --label $topic
        | from json
        | get result.workspace)
    let ws_id = $created.workspace_id

    # 2. 取 workspace 的默认 root pane 的 pane_id
    let root = (herdr api snapshot
        | from json
        | get result.snapshot.panes
        | where workspace_id == $ws_id
        | last)
    let pane_id = ($root | get pane_id)

    # 3. 若 pane 还没跑 claude, 启动它（项目内启动无需交互确认）
    if ($root.agent? | default '?') != 'claude' {
        herdr pane run $pane_id "claude" | ignore
    }

    # 4. 轮询等 sid 出现（claude 起来后 SessionStart hook 上报）
    mut sid = ''
    for i in 1..12 {
        sleep 5sec
        let snap2 = (herdr api snapshot | from json | get result.snapshot)
        let matches = ($snap2.agents | where pane_id == $pane_id)
        if ($matches | is-empty) {
            continue
        }
        let ag = ($matches | first)
        let candidate = ($ag.agent_session?.value? | default '')
        if ($candidate | str length) > 20 {
            $sid = $candidate
            break
        }
    }

    if ($sid | is-empty) {
        {topic: $topic, pane_id: $pane_id, sid: '', status: 'no-sid'}
    } else {
        {topic: $topic, pane_id: $pane_id, sid: $sid, status: 'ok'}
    }
}

# ─── 辅助：ccx export + 自动重试（ccx 偶尔 AI 分类失败, 重试可自助恢复） ───
def ccx-export-with-retry [
    sid: string
    topic: string
    --attempts: int = 3
    --delay: duration = 3sec
]: nothing -> record<ok: bool export_path: string error: string> {
    mut last = {ok: false, export_path: '', error: ''}
    for i in 1..$attempts {
        let res = (^ccx session export --session $sid --output-dir $EXPORT_DIR o+e>| complete)
        let out = ($res.stdout | str trim)
        if $res.exit_code == 0 {
            let path = ($out | str replace 'Exported session to ' '' | str trim)
            return {ok: true, export_path: $path, error: ''}
        }
        $last = {ok: false, export_path: '', error: $out}
        if $i < $attempts {
            print $'  ↻ ($topic): ccx 第($i)/($attempts)次失败, 等待 ($delay) 重试...'
            sleep $delay
        }
    }
    $last
}

# ─── 辅助：等待单个 pane 的 marker 等自动 uu / conclusion / export ───
def process-pane [
    pane: record<topic: string pane_id: string sid: string>
]: nothing -> record<topic: string status: string export_path: string> {
    let pane_id = $pane.pane_id
    let topic   = $pane.topic
    let sid     = $pane.sid

    # 1. wait marker: 精准匹配「单独一行 DONE」（regex 锚定, 避免误伤正文里的 done）
    let matched = try {
        herdr wait output $pane_id --match "^DONE$" --regex --timeout 7200000
        true
    } catch {
        print $'  ⚠️ ($topic): marker 超时'
        false
    }

    if not $matched {
        return {topic: $topic, status: 'timeout', export_path: ''}
    }

    # 2. 触发 uu: 让 pane 里的 claude 自己 cat 读取 prompt 文件后执行
    herdr agent send $pane_id $"cat ($UU_PROMPT_PATH)" | ignore
    sleep 2sec

    # 3. 触发 conclusion: 同上
    herdr agent send $pane_id $"cat ($CONCLUSION_PROMPT_PATH)" | ignore
    sleep 2sec

    # 4. ccx export + 自动重试（AI 分类偶尔失败, 重试可自助恢复）
    mkdir $EXPORT_DIR | ignore
    let ccx = (ccx-export-with-retry $sid $topic)
    if not $ccx.ok {
        print $'  ⚠️ ($topic): ccx export 最终失败'
        let err_preview = ($ccx.error | str substring 0..120)
        if ($err_preview | is-not-empty) {
            print $'    错误: ($err_preview)'
        }
        return {topic: $topic, status: 'export-fail', export_path: ''}
    }

    # 5. 收尾: 自动关闭 pane（session 内容已由 ccx 落盘, pane 无需保留）
    herdr pane close $pane_id | ignore

    {topic: $topic, status: 'done', export_path: $ccx.export_path}
}

# ─── 主入口 ───
def main [
    md_file: string        # markdown 文件路径
    topics: string         # 逗号分隔的 h2 标题, 如 'old-coder,ddd'
    --num: int = 5         # 只处理前 N 个 topic (top-K, 防堆积), 默认 5
] {
    print $'🔨 herdr-strike: 从 ($md_file) 提取指定 topic'

    # 1. 按 h2 拆, 只取指定 topic, 再截取前 num 个
    let sections_all = get-sections $md_file ($topics | split row ',')
    if ($sections_all | length) == 0 {
        print '❌ 未匹配到任何指定 h2, 退出'
        exit 1
    }
    let sections = ($sections_all | first $num)
    let topic_list = ($sections | get topic | str join ', ')
    print $'✅ 匹配到 ($sections_all | length) 个 topic, 本次处理前 ($sections | length) 个: ($topic_list)'
    print ''
    print '📋 各 topic 内容（供你在 pane 里粘贴给 claude）:'
    $sections | each {|s|
        print $'  【($s.topic)】'
        ($s.content | lines | first 5) | each {|line| print $'    ($line)' }
        print ''
    }

    # 2. 为每个 topic 建 workspace + 启动 claude
    print '🚀 创建 workspace 并启动 claude...'
    let panes = ($sections | each {|s|
        print $'  → ($s.topic)'
        let result = create-topic-pane $s.topic
        if $result.status == 'ok' {
            print $'    ✅ pane=($result.pane_id) sid=($result.sid | str substring 0..8)...'
        } else {
            print $'    ❌ ($result.status)'
        }
        $result
    })

    let active = ($panes | where status == 'ok')
    if ($active | length) == 0 {
        print '❌ 所有 pane 创建失败, 退出'
        exit 1
    }

    print ''
    print $'━━━ 已创建 ($active | length) 个 pane, 切到 herdr TUI 开始深潜 ━━━'
    print $'把对应 topic 的资料贴给每个 claude, 自由追问深潜'
    print $'聊完输: ($DONE_MARKER)'
    print $'导出目录: ($EXPORT_DIR)'
    print '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

    # 3. 并行等所有 pane 吐 marker
    print ''
    print '⏳ 等待 marker...'

    let completed = ($active | par-each {|p|
        let result = process-pane $p
        print $'  ✅ ($p.topic): ($result.status)'
        $result
    } | collect)

    # 4. 汇总
    print ''
    print '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    print '📦 所有 topic 处理完成!'
    print '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    $completed | select topic status export_path
}
