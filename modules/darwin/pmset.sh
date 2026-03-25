#
# pmset: macOS 电源管理。改配置通常需要 root 权限。
# 常用查看：
#   pmset -g custom        # 查看当前生效的电源配置
#   pmset -g assertions    # 看是谁在阻止睡眠/关屏（非常常见的“怎么不睡”原因）
#

# ----------------------------
# 插电（-c = charger / AC power）
# ----------------------------
/usr/bin/pmset -c \
  displaysleep 10 \   # 显示器在空闲 10 分钟后关闭（单位：分钟；0=永不关屏）:contentReference[oaicite:3]{index=3}
  sleep 30            # 系统在空闲 30 分钟后进入睡眠（单位：分钟；0=永不睡眠）:contentReference[oaicite:4]{index=4}

# ----------------------------
# 电池（-b = battery）
# ----------------------------
/usr/bin/pmset -b \
  displaysleep 5 \    # 电池模式下：5 分钟关屏（更省电）:contentReference[oaicite:5]{index=5}
  sleep 15            # 电池模式下：15 分钟系统睡眠:contentReference[oaicite:6]{index=6}

# ----------------------------
# 全部电源条件（-a = all：AC + Battery + UPS）
# 这里主要是“睡眠之后到底怎么省电/要不要写盘/多久进入更深省电状态”
# ----------------------------
/usr/bin/pmset -a \
  hibernatemode 3 \   # 休眠模式：3 通常表示“RAM 继续供电以便快速唤醒 + 同时写入休眠镜像以防断电”
                       # （不同机型/系统会有差异，但 3 是很常见的默认语义之一）:contentReference[oaicite:7]{index=7}
  standby 1 \         # 开启 standby：睡眠一段时间后进入更深层省电状态（可能会写镜像并断 RAM 供电）:contentReference[oaicite:8]{index=8}
  autopoweroff 1      # 开启 autopoweroff：更深省电/“自动断电”相关机制（硬件支持时生效）:contentReference[oaicite:9]{index=9}

/usr/bin/pmset -a \
  standbydelayhigh 86400 \  # 电量较高时：从进入睡眠开始，等待 86400 秒(=24小时)后再进入 standby 深省电:contentReference[oaicite:10]{index=10}
  standbydelaylow 10800     # 电量较低时：等待 10800 秒(=3小时)后进入 standby 深省电:contentReference[oaicite:11]{index=11}
                             # high/low 的切换由电量阈值（highstandbythreshold 等）决定:contentReference[oaicite:12]{index=12}
