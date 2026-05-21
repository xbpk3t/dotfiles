// Sub-Store Operator: 节点名前加机场名前缀（参考实现）
// 实际使用见 sub-store.json 中各 subscription 的 inline Script Operator

const PROVIDER_PREFIX = '[provider]';

function operator(proxies, targetPlatform) {
  return proxies.map((proxy, index) => {
    const next = { ...proxy };
    const rawName = String(next.name || `node-${index + 1}`).trim();
    if (rawName.startsWith(PROVIDER_PREFIX)) {
      next.name = rawName;
    } else {
      next.name = `${PROVIDER_PREFIX} ${rawName}`;
    }
    return next;
  });
}

function filter(proxies, targetPlatform) {
  return proxies.map(() => true);
}
