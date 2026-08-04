#!/usr/bin/env nu
# strike.nu — counter 读-改-写（/tmp/zzz/strike/<topic>.txt）
# 文件名 = topic = key，内容 = 数字（当前 turn）
#
# Usage:
#   nu strike.nu reset <topic>   # 主 agent 创建 sub-agent 时初始化，turn=1
#   nu strike.nu bump <topic>    # sub-agent 每轮第一步：读+1+写回，输出 turn 值
#
# 输出（sub-agent 只认这个，禁止自己数）：
#   [strike] Topic=.. Turn=N/3
#   [strike] Topic=.. Turn=N/3 HARD_STOP   (N>3)

def main [action: string, topic: string] {
    let dir = "/tmp/zzz/strike"
    mkdir $dir
    let f = ($dir | path join $"($topic).txt")

    match $action {
        "reset" => {
            "1" | save --force $f
            print $"[strike] Topic=($topic) Turn=1/3"
        }
        "bump" => {
            let n = ((if ($f | path exists) { open --raw $f | into int } else { 0 }) + 1)
            $n | to text | save --force $f
            if $n > 3 {
                print $"[strike] Topic=($topic) Turn=($n)/3 HARD_STOP"
            } else {
                print $"[strike] Topic=($topic) Turn=($n)/3"
            }
        }
        _ => {
            error make { msg: $"unknown action: ($action)。可用: reset / bump" }
        }
    }
}
