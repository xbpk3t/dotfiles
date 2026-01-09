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
      {
        format = "binary";
        tag = "AdGuardSDNSFilter";
        type = "remote";
        url = "http://sbx.lmd1n2s3.cc:21088/sbx/AdGuardSDNSFilterSingBox.srs";
        download_detour = "direct";
      }
      # https://github.com/curl/curl/wiki/DNS-over-HTTPS
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
