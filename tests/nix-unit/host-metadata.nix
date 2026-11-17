# nix-unit suite：fleet registry 不变量。
#
# 断言从 hosts/**/meta.nix 驱动生成，新增/改名节点时测试自动跟上。
# 具体不变量集中在 lib/fleet/default.nix 的 checks attrset；这里只做
# “布尔值 -> nix-unit case”的机械转换，避免测试逻辑和数据逻辑各写一份。
#
# nix-unit 的两个要点（都踩过坑，写在注释里留档）：
#   - 用例叶子 name 必须以 `test` 开头，否则 nix-unit 在计数里会直接忽略 → 测试“假绿”。
#   - `expr` / `expected` 是「在这个 Nix 语境里已经求值好的值」，不是字符串表达式；
#     判定方式是 `expr == expected` 的 Nix 全等。所以这里把断言写成真正的布尔值：
#     expr 算成 true ⇔ 数据一致；false ⇔ 违约（与 expected=true 不匹配 → 报红）。
{ lib }:
let
  fleet = import ../../lib/fleet { inherit lib; };
in
builtins.mapAttrs (_name: value: {
  expr = value;
  expected = true;
}) fleet.checks
