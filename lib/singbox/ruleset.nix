# NOTE: 使用新的 rule-set 方式 (sing-box 1.8.0+)，而非被 deprecated 的旧 GeoIP/Geosite 功能
# 旧方式：在 route 配置中直接定义 geoip/geosite 字段（1.12.0 已移除）
# 新方式：使用 rule_set 对象，通过远程 .srs 文件加载规则集
# 参考: https://sing-box.sagernet.org/configuration/route/rule_set/
{
  ruleSetSource ? "primary",
  enableRuleSetExtras ? false,
  customRuleSets ? [],
  geoipNames ? [
    "cn"
  ],
  geositeNames ? [
    "geolocation-cn"
    "steam"
    "openai"
    "category-ads-all"
  ],
}: let
  ruleSetUrls =
    if ruleSetSource == "fallback"
    then {
      geoip = name: "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/${name}.srs";
      geosite = name: "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/${name}.srs";
    }
    else {
      geoip = name: "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-${name}.srs";
      geosite = name: "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-${name}.srs";
    };

  mkGeoipRuleSet = name: {
    tag = "geoip-${name}";
    type = "remote";
    format = "binary";
    url = ruleSetUrls.geoip name;
  };
  mkGeositeRuleSet = name: {
    tag = "geosite-${name}";
    type = "remote";
    format = "binary";
    url = ruleSetUrls.geosite name;
  };

  extraRuleSets =
    if enableRuleSetExtras
    then [
      # https://github.com/xmdhs/sing-box-ruleset
      # AdGuard 官方提供了原始的 AdGuard DNS Filter（简化域名过滤列表），用于 DNS 级广告和跟踪阻挡。
      # sing-box 官方不支持直接加载 AdGuard 的 txt 格式，需要先用 sing-box 工具转换为二进制 .srs 格式。因此，没有 SagerNet/sing-box 官方提供的预转换 .srs 文件。
      {
        format = "binary";
        tag = "AdGuardSDNSFilter";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/AdGuardSDNSFilterSingBox.srs";
        download_detour = "direct";
      }
      # https://github.com/curl/curl/wiki/DNS-over-HTTPS
      # Google Chrome 本身有内置的 DoH 提供商列表（用于自动升级功能），但 Google 没有公开一个独立的 JSON 文件 作为“Chrome DoH servers list”。
      # Chrome 浏览器内置或支持的 DNS over HTTPS (DoH) 服务器列表（域名或模板），用于在 sing-box 的 DNS 规则中匹配并特殊处理（如强制使用特定上游或绕过）。
      {
        format = "source";
        tag = "chrome-doh";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/chrome-doh.json";
        download_detour = "direct";
      }
    ]
    else [];
in
  (map mkGeoipRuleSet geoipNames)
  ++ (map mkGeositeRuleSet geositeNames)
  ++ extraRuleSets
  ++ customRuleSets
