#!/usr/bin/env nu
# herdr-z finish action — 结束 herdr session 的收尾
#
# 触发: command-palette fzf 选 "Finish session"
# 流程: /zzz uu → /zzz conclusion → ccx export
#
# 目标 pane 定位:
#   1. HERDRZ_TARGET_PANE 显式指定 (调试; 注意不能用 HERDR_ 前缀, 会被 herdr scrub)
#   2. snapshot 焦点 pane (palette 触发时焦点还在目标 pane)
#   3. 兜底: cwd == 当前 PWD 的 claude agent

let EXPORT_DIR = '/tmp/herdr-z-export'
const WAIT_TIMEOUT = 600000      # 等 claude 回合完成 (ms)
const RETRY_DELAY = 3sec
const SENTINEL_EMPTY = 'session is empty'

# ── 目标 pane 定位 ──
def find-target-pane []: nothing -> record<pane_id: string sid: string cwd: string status: bool> {
    let snapshot = (^herdr api snapshot | from json | get result.snapshot)

    # 1. 显式指定 (调试/高级)
    let explicit = ($env.HERDRZ_TARGET_PANE? | default '')
    if ($explicit | is-not-empty) {
        return (find-agent-by-pane $snapshot $explicit)
    }

    # 2. 焦点 pane
    let focused_id = ($snapshot.focused_pane_id | default '')
    if ($focused_id | is-not-empty) {
        let found = (find-agent-by-pane $snapshot $focused_id)
        if $found.status {
            return $found
        }
    }

    # 3. 兜底: 按 cwd 匹配
    let cwd = (pwd)
    let agents = ($snapshot.agents | where cwd == $cwd and agent == 'claude')
    if ($agents | is-empty) {
        return {pane_id: '', sid: '', cwd: '', status: false}
    }
    let with_sid = ($agents | where agent_session? != null)
    let ag = if ($with_sid | is-not-empty) { $with_sid | first } else { $agents | first }
    {
        pane_id: ($ag | get pane_id),
        sid: ($ag.agent_session?.value? | default ''),
        cwd: ($ag.cwd? | default ''),
        status: ($ag.agent_session?.value? | default '' | is-not-empty)
    }
}

# 在 snapshot 里按 pane_id 找 agent, 统一构造返回值
def find-agent-by-pane [
    snapshot: record
    pane_id: string
]: nothing -> record<pane_id: string sid: string cwd: string status: bool> {
    let matches = ($snapshot.agents | where pane_id == $pane_id)
    if ($matches | is-empty) {
        return {pane_id: $pane_id, sid: '', cwd: '', status: false}
    }
    let ag = ($matches | first)
    let sid = ($ag.agent_session?.value? | default '')
    {
        pane_id: $pane_id,
        sid: $sid,
        cwd: ($ag.cwd? | default ''),
        status: ($sid | is-not-empty)
    }
}

# 等 claude 完成当前回合
def wait-idle [pane_id: string, --timeout: int = 600000]: nothing -> bool {
    try {
        ^herdr wait agent-status $pane_id --status idle --timeout $timeout
        true
    } catch {
        false
    }
}

# 发送 slash 命令并提交 (回车)
def send-slash [pane_id: string, cmd: string]: nothing -> nothing {
    ^herdr agent send $pane_id $cmd | ignore
    ^herdr pane send-keys $pane_id Enter | ignore
}

# 执行 ccx export 一次, 返回完整结果
def ccx-export-once [
    sid: string
]: nothing -> record<ok: bool output: string> {
    let res = (^ccx session export --session $sid --output-dir $EXPORT_DIR o+e>| complete)
    {ok: ($res.exit_code == 0), output: ($res.stdout | str trim)}
}

def main [] {
    print '🔧 herdr-z finish...'

    # 1. 定位目标 pane
    let target = find-target-pane
    if not $target.status {
        print '❌ 无法定位目标 pane (cwd 无匹配的 claude agent)'
        print $"   当前 PWD: (pwd)"
        print '   可用: HERDRZ_TARGET_PANE=<pane_id> 显式指定'
        exit 1
    }
    print $"  ✅ 目标 pane: ($target.pane_id) sid=($target.sid | str substring 0..12)..."

    # 2. /zzz uu
    print '  [1/3] /zzz uu...'
    send-slash $target.pane_id '/zzz uu'
    if (wait-idle $target.pane_id) {
        print '  ✅ uu done'
    } else {
        print '  ⚠️ uu 超时, 继续'
    }
    sleep 2sec

    # 3. /zzz conclusion
    print '  [2/3] /zzz conclusion...'
    send-slash $target.pane_id '/zzz conclusion'
    if (wait-idle $target.pane_id) {
        print '  ✅ conclusion done'
    } else {
        print '  ⚠️ conclusion 超时, 继续'
    }
    sleep 2sec

    # 4. ccx export — 外部执行 (retry 完全由脚本控制)
    #    空会话 → ccx 返回 sentinel, 跳过不 retry (重试永远失败)
    #    其他失败 → retry 最多 2 次
    print '  [3/3] ccx export...'
    mkdir $EXPORT_DIR | ignore
    # ccx 从 cwd 解析项目目录找 transcript; 切到 pane 的 cwd 保证正确
    if ($target.cwd | is-not-empty) and ($target.cwd | path exists) {
        cd $target.cwd
    }

    mut result = (ccx-export-once $target.sid)
    if $result.ok {
        print $"  ✅ export: ($result.output)"
    } else if ($result.output =~ $SENTINEL_EMPTY) {
        print '  ⏭️  空会话 (无内容可导出), 跳过'
    } else {
        print $"  ⚠️ export 失败: ($result.output | str substring 0..120)"
        for i in 1..2 {
            print $"  ↻ retry ($i)/2..."
            sleep $RETRY_DELAY
            $result = (ccx-export-once $target.sid)
            if $result.ok {
                print $"  ✅ export (retry): ($result.output)"
                break
            }
        }
        if not $result.ok {
            print '  ❌ export 最终失败'
        }
    }

    print ''
    print '🎉 herdr-z finish 完成! (uu + conclusion + export)'
}
