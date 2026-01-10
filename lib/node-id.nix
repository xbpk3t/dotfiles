{lib}: {
  roleName,
  targetHost,
}: let
  # 统一生成节点唯一 ID：
  # 1) 不依赖系统 hostname（避免多机同名冲突）
  # 2) 只依赖 colmena 的 targetHost，保证可复现
  # 3) 便于在各模块里用同一套规则生成域名/标识
  sanitize = host:
    lib.strings.sanitizeDerivationName (
      lib.strings.replaceStrings ["." ":" "/"] ["-" "-" "-"] host
    );
in "${roleName}-${sanitize targetHost}"
