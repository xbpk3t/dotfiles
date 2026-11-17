{
  fleet,
}:
let
  pathIfExists = path: if builtins.pathExists path then path else null;
in
{
  # What：仅在 report 文件真实存在时返回路径。
  # Why：让 host 可以渐进接入 nixos-facter，不会因为缺少 facter.json 直接打断现有 build。
  reportPathIfExists = pathIfExists;

  # What：读取一个 facter report JSON。
  # Why：给 tests / 纯函数逻辑提供统一入口，避免各处重复 builtins.fromJSON。
  readReport =
    path:
    let
      reportPath = pathIfExists path;
    in
    if reportPath == null then null else builtins.fromJSON (builtins.readFile reportPath);

  # What：约定每台主机的 report 放在该节点自身的目录（hosts/<group>/<node>/facter.json
  #   或 hosts/<node>/facter.json，以 fleet 派生出的 node.path 为准）。
  # Why：让 report 与对应 host 配置同目录收敛，维护和 review 都更直观；
  #   路径只从 fleet 取，不再回退到 hosts/<hostName> 的旧扁平布局。
  #   未知 host 返回 null，保持 helper 的可探测语义。
  reportPathForHost =
    hostName:
    let
      node = fleet.nodes.${hostName} or null;
    in
    if node == null then null else pathIfExists (node.path + "/facter.json");
}
