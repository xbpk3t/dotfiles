# 由硬件事实派生调优档位的唯一映射。
#
# 事实来源是 hosts/<...>/meta.nix 的 `hardware.memGiB`。
# 这里只做“内存规模 -> 默认策略”的映射：
#   - sysctl mode（内核/网络调优激进程度）
#   - PAM limits profile（每个登录进程的资源限制）
#
# 两个档位仍然可以在 host 上显式覆盖：
#   - modules.kernel.sysctl.mode
#   - modules.kernel.limits.profile
# 但正常 host 只需要维护 memGiB。
_:
let
  profileFor =
    memGiB:
    if memGiB == null then
      # 没有硬件事实时保持保守默认。
      {
        mode = "bal";
        limits = "baseline";
      }
    else if memGiB <= 2 then
      {
        mode = "steady";
        limits = "baseline";
      }
    else if memGiB <= 4 then
      {
        mode = "bal";
        limits = "baseline";
      }
    else if memGiB <= 32 then
      {
        mode = "perf";
        limits = "baseline";
      }
    else
      {
        # 大内存工作站/构建机：perf + high，但仍可在 host 上显式降级。
        mode = "perf";
        limits = "high";
      };
in
{
  inherit profileFor;
}
