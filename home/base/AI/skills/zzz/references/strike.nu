#!/usr/bin/env nu
# herdr-strike.nu — 按 temp.md 的 h2 分发到独立 herdr workspace + claude pane
#
# 用法:
#   nu herdr-strike.nu <md文件> <"h2标题1,h2标题2,..."> [--num N]
#
# 流程:
#   1. ^mq 按指定 h2 标题提取每节内容（展示给你看, 供你在 pane 里粘贴）
#   2. 为每个 topic 建 herdr workspace + 在 docs 项目内启动 claude（自动拿 sid）
#   3. 你在 herdr TUI 里切各 pane 自由深潜
#   4. 收尾: 各 pane 深潜完, 用 herdr-z plugin 的 finish action 逐 pane 收尾
#      （uu + conclusion + ccx export + close pane）— 本脚本只负责分发, 不等待收尾。
#
# 前置条件:
#   - herdr server 在运行
#   - mq 已安装

let PROJECT_DIR    = '/Users/luck/Desktop/docs'

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
        | get result)
    let ws_id = $created.workspace.workspace_id

    # 2. 直接取 workspace 的 root pane 的 pane_id（返回结构里就是 root_pane,
    #    不用 snapshot 里按 workspace 过滤再取 last —— 后者在已有多个 pane 时会取错）
    let root = $created.root_pane
    let pane_id = ($root.pane_id)

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
    print ''
    print $'深潜完成后, 逐个用 herdr-z 收尾:'
    print $'  herdr plugin action invoke herdr-z.finish   # 对当前焦点 pane 收尾'
    print $'  （或绑定快捷键直接触发）'
    print '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    print ''
    print '📊 各 pane 信息（供定位）:'
    $active | each {|p|
        print $'  ($p.topic): pane=($p.pane_id) sid=($p.sid)'
    }
}
