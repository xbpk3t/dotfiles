{lib}: let
  # 统一的字符串清洗器：保证主机标识可用作派生名/域名片段
  sanitize = host:
    lib.strings.sanitizeDerivationName (
      lib.strings.replaceStrings ["." ":" "/"] ["-" "-" "-"] host
    );
in rec {
  # 统一生成节点唯一 ID：
  # 1) 不依赖系统 hostname（避免多机同名冲突）
  # 2) 只依赖节点主机标识（如 primaryIp/ssh.host），保证可复现
  # 3) 便于在各模块里用同一套规则生成域名/标识
  nodeId = {
    roleName,
    targetHost,
  }: "${roleName}-${sanitize targetHost}";

  # 统一生成节点派生信息（hostName、DERP 域名等）：
  # - 由节点 meta 提供输入（可选）
  # - 所有派生字段从这里生成，避免模块内重复拼接
  hostMeta = {
    roleName,
    targetHost,
    nodeId,
    meta ? {},
  }: let
    domainBase = meta.derpDomainBase or meta.tailscale.derpDomainBase or "lucc.dev";
    derpPrefix = meta.derpSubdomainPrefix or meta.tailscale.derpSubdomainPrefix or "derp";
    hostName = meta.hostName or nodeId;
    derpDomain = meta.derpDomain or meta.tailscale.derpDomain or "${derpPrefix}-${nodeId}.${domainBase}";
  in {
    inherit roleName targetHost nodeId hostName derpDomain;
    # 保留原始 meta 以便模块侧按需取用其它字段
    raw = meta;
  };
}
