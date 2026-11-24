# nix-unit suite：硬件事实 -> 调优档位映射。
#
# 事实来源是 hostMeta.hardware.memGiB；sysctl mode 与 limits profile
# 必须始终由同一个映射产生，避免两处阈值漂移。
{ hardwareProfile }:
let
  profile = hardwareProfile.profileFor;
in
{
  testHardwareProfileUnknown = {
    expr = profile null;
    expected = {
      mode = "bal";
      limits = "baseline";
    };
  };

  testHardwareProfile1GiB = {
    expr = profile 1;
    expected = {
      mode = "steady";
      limits = "baseline";
    };
  };

  testHardwareProfile2GiB = {
    expr = profile 2;
    expected = {
      mode = "steady";
      limits = "baseline";
    };
  };

  testHardwareProfile4GiB = {
    expr = profile 4;
    expected = {
      mode = "bal";
      limits = "baseline";
    };
  };

  testHardwareProfile6GiB = {
    expr = profile 6;
    expected = {
      mode = "perf";
      limits = "baseline";
    };
  };

  testHardwareProfile32GiB = {
    expr = profile 32;
    expected = {
      mode = "perf";
      limits = "baseline";
    };
  };

  testHardwareProfile64GiB = {
    expr = profile 64;
    expected = {
      mode = "perf";
      limits = "high";
    };
  };
}
