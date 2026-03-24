{lib, ...}: let
  mylib = import ../../../../lib {inherit lib;};
  report = mylib.facter.readReport ../../facter/basic-report.json;
  cpu0 =
    if report == null || (report.hardware.cpu or []) == []
    then {}
    else builtins.head report.hardware.cpu;
  disk0 =
    if report == null || (report.hardware.disk or []) == []
    then {}
    else builtins.head report.hardware.disk;
in {
  format = "json";
  expr = {
    system = report.system or null;
    virtualisation = report.virtualisation or null;
    cpuCount = builtins.length (report.hardware.cpu or []);
    diskCount = builtins.length (report.hardware.disk or []);
    graphicsCount = builtins.length (report.hardware.graphics_card or []);
    firstCpu = {
      architecture = cpu0.architecture or null;
      vendor = cpu0.vendor_name or null;
      cores = cpu0.cores or null;
    };
    firstDisk = {
      model = disk0.model or null;
      driver = disk0.driver or null;
      driverModule = disk0.driver_module or null;
    };
    missingReportPath = mylib.facter.reportPathIfExists ../../facter/missing-report.json;
  };
}
