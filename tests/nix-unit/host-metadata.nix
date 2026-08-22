# nix-unit suite：host 元数据一致性断言。
#
# 为什么单独一个文件而不是手写在 outputs/default.nix：
#   - 断言从 inventory（lib/inventory/data.nix）**驱动生成**，新增/改名节点时测试自动跟上，
#     不需要人手维护一张 host 清单。
#   - nix-unit 的 suite 是「固有 attr」（name -> { expr, expected }），用数据折叠生成最干净。
#
# nix-unit 的两个要点（都踩过坑，写在注释里留档）：
#   - 用例叶子 name 必须以 `test` 开头，否则 nix-unit 在计数里会直接忽略 → 测试“假绿”。
#   - `expr` / `expected` 是「在这个 Nix 语境里已经求值好的值」，不是字符串表达式；
#     判定方式是 `expr == expected` 的 Nix 全等。所以这里把断言写成真正的布尔值：
#     expr 算成 true ⇔ 数据一致；false ⇔ 违约（与 expected=true 不匹配 → 报红）。
#
# 断言的三类契约：
#   a) hostName 必须等于节点自身的 node name（即 group 内该节点在 inventory 里的 attr key）。
#      这正是当年「nod 的 hostName≠nodeName」踩的坑——节点改名时 hostName 掉队了。
#      注意：刻意不用「hostName==groupName」。像 nixos-vps / sm-vps 这种「一组多机」的 group，
#      节点 host（nixos-vps-dev / sm-vps-hk …）天然 != group 名，那不是 bug；真正的不变量是
#      「每个节点 hostName == 它自己的 node key」。
#   b) user 必须继承 commonUser：username == "luck"，不允许再凭猜写死。
#   c) stateVersion 非空；且一旦声明 user.uid 就必须同时有 gid，且两者都 >0
#     （不允许用 0 占位：任何声明了 uid 的节点都必须给真实 uid/gid——曾经的 nod 就用 0 占位踩过坑）。
_:
let
  data = import ../../lib/inventory/data.nix;

  # 展平 inventory：把每个 (<group> × <node key>) 变成一条含全部相关元数据的记录。
  nodes = builtins.concatMap (
    g:
    builtins.map (
      n:
      let
        node = data.${g}.${n};
        user = node.user or { };
      in
      {
        inherit g;
        node = n;
        host = node.hostName or n;
        state = node.stateVersion or "";
        inherit user;
      }
    ) (builtins.attrNames data.${g})
  ) (builtins.attrNames data);

  # 一条用例。`key` 只是可读标签（前缀 test），`assertion` 是被直接求值的布尔值。
  one = key: assertion: {
    "test-${key}" = {
      expr = assertion;
      expected = true;
    };
  };
in
builtins.foldl' (acc: c: acc // c) { } (
  # a) hostName == nodeName（每个节点自己的 key）。
  (map (r: one "host-${r.g}/${r.node}: hostName == nodeName" (r.host == r.node)) nodes)
  # b) user.username == commonUser（luck)
  ++ (map (
    r: one "user-${r.g}/${r.node}: username == commonUser 'luck'" (r.user.username or null == "luck")
  ) nodes)
  # c1）stateVersion 非空。
  ++ (map (r: one "state-${r.g}/${r.node}: stateVersion non-empty" (r.state != "")) nodes)
  # c2）有 uid 就必须有 gid 且两者都 > 0。
  ++ (builtins.concatLists (
    map (
      r:
      if r.user.uid or null == null then
        [ ]
      else
        [
          (one "uid-${r.g}/${r.node}: uid/gid > 0 && paired" (r.user.uid > 0 && (r.user.gid or (0)) > 0))
        ]
    ) nodes
  ))
)
