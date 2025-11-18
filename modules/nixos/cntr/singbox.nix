_:
{
  # https://github.com/alireza0/s-ui
  # https://github.com/alireza0/s-ui-frontend

  # https://github.com/233boy/sing-box
  # [最好用的 sing-box 一键安装脚本 - 233Boy](https://233boy.com/sing-box/sing-box-script/)
  # https://github.com/yonggekkk/sing-box-yg
  # https://github.com/mack-a/v2ray-agent

  # https://linux.do/t/topic/1146113/5

  # PLAN [2025-10-11] 与其自建节点，不如直接打野抓别人的节点。在自建之前先搞下这个。我感觉打野搭配 sub-store会很有用。
  # 【翻墙的终极解决方案】
  # 简单来说，就是 打野/机场 和 自建 互为灾备、互为冗余，具体来说，打野+自动扔进sub-store做测速（测速、筛选节点、删除无效节点等），自动按照latency排序，给我下发订阅URL（之后多端的singbox直接拉URL，本地不需要任何操作，默认使用）。
  # 打野（做中转, GroupPool）和自建（做落地鸡, GroupSelf）互为failover，两个其中任一挂了，直接另一个走直连。
  # 自建组两台机器，一台LA机器，DMIT大妈的的T1（我的主力落地鸡，美西节点，服务全开，¥37/年（折合来说¥12/月，比机场便宜），1C1G20GB1TB流量千兆带宽，网络好配置差，只做落地鸡（BWG 类似配置但是2C的机器$50/年）），另一台HK机器（备用落地鸡，我的主力VPS兼作落地，sub-store就在这台机器上跑，跑完把订阅URL分发到我所有workstation和homelab机器上）
  # 我的所有机器都直接走VLAN，不走公网，所以不需要担心被人打野
}
F
