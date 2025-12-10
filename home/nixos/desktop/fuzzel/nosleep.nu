#!/usr/bin/env nu

def main [action: string = "status"] {

    let systemctl = "systemctl"
    let sudo = "sudo"

    match $action {
        "on" | "start" => {
            ^$sudo $systemctl start nosleep
            let code = $env.LAST_EXIT_CODE
            if $code == 0 {
                print "✅ nosleep 已开启：系统会阻止 sleep。"
            } else {
                print $"❌ nosleep 开启失败（systemctl 退出码: ($code)）。"
            }
        }

        "off" | "stop" => {
            ^$sudo $systemctl stop nosleep
            let code = $env.LAST_EXIT_CODE
            if $code == 0 {
                print "✅ nosleep 已关闭：系统恢复正常 sleep 行为。"
            } else {
                print $"❌ nosleep 关闭失败（systemctl 退出码: ($code)）。"
            }
        }

        "status" => {
            # 不再用 --quiet，直接看输出文本
            let result = ( ^$systemctl is-active nosleep | str trim )

            if $result == "active" {
                print "ℹ️ nosleep 当前状态：ON（正在阻止 sleep）。"
            } else if $result == "inactive" {
                print "ℹ️ nosleep 当前状态：OFF（未阻止 sleep）。"
            } else {
                print $"⚠️ 无法确认 nosleep 状态：systemctl is-active 返回 '($result)'。"
            }
        }

        "toggle" => {
            let result = ( ^$systemctl is-active nosleep | str trim )

            if $result == "active" {
                ^$sudo $systemctl stop nosleep
                let code2 = $env.LAST_EXIT_CODE
                if $code2 == 0 {
                    print "🔁 nosleep: ON → OFF"
                } else {
                    print $"❌ 切换到 OFF 失败（systemctl 退出码: ($code2)）。"
                }
            } else {
                ^$sudo $systemctl start nosleep
                let code2 = $env.LAST_EXIT_CODE
                if $code2 == 0 {
                    print "🔁 nosleep: OFF → ON"
                } else {
                    print $"❌ 切换到 ON 失败（systemctl 退出码: ($code2)）。"
                }
            }
        }

        _ => {
            print "用法: nosleep.nu [on|off|status|toggle]"
        }
    }
}
