# nix-unit suite：内存/swap 派生策略。
#
# 断言“内存规模 + swap 后端 -> 参数”的对应关系，防止跨主机回归：
#   - zram + 小内存要更积极换出（swappiness=100）
#   - 大内存 zram 保留默认倾向（60）
#   - 无 zram 时按 SSD/HDD 回退
#   - oom_kill_allocating_task / overcommit_memory 是显式策略，不按内存推导
{ vpsSysctl }:
let
  base = {
    bwMbps = 1000;
    rttMs = 30;
    cpuCores = 4;
  };
  sysctl = extra: vpsSysctl.mkSysctl (base // extra);
in
{
  testMemorySwappinessZramSmall = {
    expr = (sysctl { memGiB = 4; zramEnabled = true; })."vm.swappiness";
    expected = 100;
  };

  testMemorySwappinessZramLarge = {
    expr = (sysctl { memGiB = 16; zramEnabled = true; })."vm.swappiness";
    expected = 60;
  };

  testMemorySwappinessDiskSsd = {
    expr = (sysctl { memGiB = 4; zramEnabled = false; isSsd = true; })."vm.swappiness";
    expected = 60;
  };

  testMemorySwappinessDiskHdd = {
    expr = (sysctl { memGiB = 4; zramEnabled = false; isSsd = false; })."vm.swappiness";
    expected = 20;
  };

  testMemoryOomKillAllocatingTaskDefault = {
    expr = (sysctl { memGiB = 4; })."vm.oom_kill_allocating_task";
    expected = 0;
  };

  testMemoryOomKillAllocatingTaskOptIn = {
    expr = (sysctl { memGiB = 4; oomKillAllocatingTask = true; })."vm.oom_kill_allocating_task";
    expected = 1;
  };

  testMemoryOvercommitDefault = {
    expr = (sysctl { memGiB = 4; })."vm.overcommit_memory";
    expected = 1;
  };

  testMemoryOvercommitOverride = {
    expr = (sysctl { memGiB = 4; overcommitMemory = 0; })."vm.overcommit_memory";
    expected = 0;
  };

  testMemoryZramProfileSmall = {
    expr = vpsSysctl.mkZramProfile { memGiB = 4; };
    expected = {
      memoryPercent = 50;
      memoryMax = 4 * 1024 * 1024 * 1024;
    };
  };

  testMemoryZramProfileLarge = {
    expr = vpsSysctl.mkZramProfile { memGiB = 16; };
    expected = {
      memoryPercent = 25;
      memoryMax = 4 * 1024 * 1024 * 1024;
    };
  };

  testMemoryZramProfileUnknown = {
    expr = vpsSysctl.mkZramProfile { };
    expected = {
      memoryPercent = 25;
      memoryMax = 4 * 1024 * 1024 * 1024;
    };
  };
}
