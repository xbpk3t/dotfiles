# terranix 第二个试点：把 tailscale/tailnet 从 HCL 迁到 Nix。
#
# 生成：
#   task tf:terranix-tailscale
# 等价命令（仓库根目录）：
#   nix develop .#infra --command bash -c \
#     'terranix --with-nulls infra/stacks/homelab/tailscale/tailnet/terranix.nix \
#        | jq -S . > infra/stacks/homelab/tailscale/tailnet/generated.tf.json'
#
# 回退：本 commit 删除了同目录的 main.tf / locals.tf / imports.tf /
# versions.tf / provider.tf，`git revert` 即可恢复。
{ lib, ... }:
let
  facts = import ../../../../facts.nix;

  # fleet 是 hosts/**/meta.nix 的派生视图；tailnet IP/设备名从 meta.nix 取，
  # 不在 Terraform 里再写一份。
  fleet = import ../../../../../lib/fleet { inherit lib; };

  # 手机不是 fleet 节点，是唯一留在本地的地址事实。
  phoneIp = "100.123.207.1";

  hmPaIp = fleet.nodes."hm-lightvela".tailscale.ip;
  macosIp = fleet.nodes."macos-ws".tailscale.ip;
  # agt 的 DERP 事实（域名/公网 IP）与 DNS/ACME 同源，见 hosts/nixos-vps/agt/meta.nix。
  agtNode = fleet.nodes."nixos-vps-agt";
  agtIp = agtNode.tailscale.ip;

  owner = "xbpk3t@github";

  # ── 角色 / 能力模型 ─────────────────────────────────────────────
  # 暴露面 role：vps（公网/低信任）、ws（个人设备/高信任）。
  # 能力 tag：svc（Tailscale Services host）、exit（exit node）、ssh（SSH 目标）。
  # tag 是扁平的；一台设备可以叠加多个（dev = vps + svc + exit）。
  tagOwners = {
    "tag:vps" = [ owner ];
    "tag:ws" = [ owner ];
    "tag:svc" = [ owner ];
    "tag:exit" = [ owner ];
  };

  # 一次性/非 fleet 管理设备的 host alias。
  # 注意：ACL 里直接写 hostname 会被控制面拒绝（invalid address）；
  # 在 hosts 里定义别名，再用别名写 grants/tests。
  # （SSH 规则的 src/dst 不接受 host alias/IP，只能用 user/group/tag/autogroup。）
  hosts = {
    "macos-ws" = macosIp;
    "hermes-wb" = hmPaIp;
    "agt" = agtIp;
    "nod-am" = phoneIp;
  };

  grants = [
    # 个人设备 → VPS/hermes：只开 SSH（部署/开发）。
    {
      src = [ "tag:ws" ];
      dst = [ "tag:vps" ];
      ip = [ "22" ];
    }
    # 个人设备之间：只开 SSH；其他端口用 SSH 隧道或按需加。
    {
      src = [ "tag:ws" ];
      dst = [ "tag:ws" ];
      ip = [ "22" ];
    }
    # VPS/hermes 之间：只开 SSH；Nezha 走单独的 8008。
    {
      src = [ "tag:vps" ];
      dst = [ "tag:vps" ];
      ip = [ "22" ];
    }
    # Nezha agent → hub（dev 带 tag:svc）。
    {
      src = [ "tag:vps" ];
      dst = [ "tag:svc" ];
      ip = [ "8008" ];
    }
    # 个人设备 → Tailscale Services VIPs。
    {
      src = [ "tag:ws" ];
      dst = [
        "svc:9router"
        "svc:nezha"
      ];
      ip = [ "80" ];
    }
    # 手机 exit node：只给 nod-am（IP 别名），Mac 不配 exit；只允许走 tag:exit（dev）。
    # 手机已打 tag:ws：服务/SSH 网络权限由 tag:ws 规则覆盖，这里只保留手机专属的 exit。
    {
      src = [ "nod-am" ];
      dst = [ "autogroup:internet" ];
      ip = [ "*" ];
      via = [ "tag:exit" ];
    }
    # hm PA local-build exit node：PA 只在构建 HM generation 时用 dev，
    # 构建完成后会清掉 exit node。只允许走 tag:exit。
    {
      src = [ "hermes-wb" ];
      dst = [ "autogroup:internet" ];
      ip = [ "*" ];
      via = [ "tag:exit" ];
    }
    # peer relay：只允许 Mac/hermes 用 agt 做 UDP 中继。
    # 两端都在 NAT 后，Mac 侧对称 NAT；peer relay 只在直连失败时启用，
    # 不改 home DERP，所以不会影响 Mac↔dev（见 LUC-555）。
    {
      src = [
        "macos-ws"
        "hermes-wb"
      ];
      dst = [ "agt" ];
      app = {
        "tailscale.com/cap/relay" = [ ];
      };
    }
    # hm PA 本地 build（hm_build_network=proxy）经 agt mihomo 代理拉 GitHub。
    # agt 主机防火墙只对 hmPaIp 放行 7890；这里用 host alias 保持同一最小权限。
    {
      src = [ "hermes-wb" ];
      dst = [ "agt" ];
      ip = [ "7890" ];
    }
    # agt 上只绑 tailnet IP 的个人服务：CloudCLI UI（3001）+ x11vnc（5900）。
    # 旧 *→* 允许 Mac/手机直接访问；最小权限下只开 ws → agt 的这两个端口。
    {
      src = [ "tag:ws" ];
      dst = [ "agt" ];
      ip = [
        "3001"
        "5900"
      ];
    }
    # NOTE(2026-11-21): 维护通道，不是最终信任模型。
    # agt 是公网 VPS；这里只允许 agt → macos-ws:22，用于从 agt 部署/维护 Mac。
    # 等有固定的、可信的开发机后删除这条 grant，恢复 vps↛ws。
    {
      src = [ "agt" ];
      dst = [ "macos-ws" ];
      ip = [ "22" ];
    }
  ];

  # ── DERP map（方案 B：只把 agt 加进来）──────────────────────────
  # agt（上海）作为低延迟 DERP fallback；保留默认 region。
  # dev(LA) / tc(SGP) 不加入：dev→agt TCP 10043 被 GFW 挡，
  # 加入后会重演 cn-sh 的 Mac↔dev 单向回归；tc 机器已不在线。
  derpMap = {
    OmitDefaultRegions = false;
    Regions = {
      "900" = {
        RegionID = 900;
        RegionCode = "agt";
        RegionName = "agt-sh";
        Nodes = [
          {
            Name = "900a";
            RegionID = 900;
            HostName = agtNode.derper.domain;
            IPv4 = agtNode.publicIpv4;
            DERPPort = 10043;
            STUNPort = 10078;
          }
        ];
      };
    };
  };

  aclBase = {
    inherit
      tagOwners
      hosts
      grants
      derpMap
      ;

    autoApprovers = {
      # 只允许带 tag:exit 的设备自动批准 exit node（当前只有 dev）。
      # 不再用用户身份或 service tag 自动批准；routes 已删（没有 subnet router）。
      exitNode = [ "tag:exit" ];
      services = {
        "svc:9router" = [ "tag:svc" ];
        "svc:nezha" = [ "tag:svc" ];
      };
    };
  };

  aclFinal = aclBase // {
    # 防止以后改 ACL 时回归。tests 在 policy 变更时由控制面执行，
    # 失败会拒绝整份 policy。
    tests = [
      {
        src = "tag:ws";
        accept = [
          "tag:vps:22"
          "tag:ws:22"
          "svc:9router:80"
          "svc:nezha:80"
        ];
        deny = [
          "tag:vps:80"
          "198.51.100.8:22"
        ];
      }
      {
        src = "tag:vps";
        accept = [
          "tag:vps:22"
          "tag:svc:8008"
        ];
        deny = [ "tag:ws:22" ];
      }
      {
        src = "nod-am";
        accept = [
          "svc:9router:80"
          "svc:nezha:80"
        ];
      }
      {
        # 回归：hm PA 的默认 build 路径依赖 agt mihomo 代理（7890）。
        src = "hermes-wb";
        accept = [ "agt:7890" ];
      }
      {
        # 回归：agt 上只绑 tailnet IP 的个人服务（CloudCLI / x11vnc）。
        src = "tag:ws";
        accept = [
          "agt:3001"
          "agt:5900"
        ];
      }
    ];
  };

  # Phase 1：给设备打 tag / 重新认证期间保留 *→*，避免默认拒绝把自己锁死。
  # 注意 `dst = "*"` 只覆盖 tailnet/子网 IP，不包含 autogroup:internet（exit node）
  # 和 app capability（peer relay），所以必须继续叠加最小权限 grants。
  # Phase 2（默认）：上面的最小权限 ACL。
  aclTagging = aclBase // {
    grants = [
      {
        src = [ "*" ];
        dst = [ "*" ];
        ip = [ "*" ];
      }
    ]
    ++ grants;
    tests = [ ];
  };

  aclFinalJson = builtins.toJSON aclFinal;
  aclTaggingJson = builtins.toJSON aclTagging;

  # 每台设备的 tag；key 是 fleet 节点名。
  deviceTags = {
    nixos-vps-dev = [
      "tag:exit"
      "tag:svc"
      "tag:vps"
    ];
    hm-lightvela = [ "tag:vps" ];
    macos-ws = [ "tag:ws" ];
    nixos-vps-agt = [ "tag:vps" ];
    nixos-wsl = [ "tag:ws" ];
  };

  tfName = lib.replaceStrings [ "-" ] [ "_" ];

  # Terraform 按 tailnet device name 索引；meta.nix 可用 tailscale.hostname
  # 覆盖派生的节点名（hm PA 的 tailnet 设备名是 hermes-wb）。
  devices = lib.mapAttrs' (
    name: tags:
    let
      node = fleet.nodes.${name};
    in
    lib.nameValuePair (node.tailscale.hostname or name) { inherit tags; }
  ) deviceTags;
in
{
  terraform = {
    required_version = ">= 1.10.0";

    required_providers.tailscale = {
      source = "tailscale/tailscale";
      version = "~> 0.18";
    };

    backend.s3 = {
      bucket = "luck-dotfiles-opentofu-state";
      key = "homelab/tailscale/tailnet/terraform.tfstate";
      region = "auto";

      endpoints.s3 = facts.cloudflare.r2_endpoint;

      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      skip_requesting_account_id = true;
      skip_s3_checksum = true;
      use_path_style = true;
      use_lockfile = true;
    };
  };

  # Phase 1 rollout 开关：
  #   tofu apply -var tailscale_acl_allow_all=true   # 打 tag / re-auth
  #   tofu apply                                      # 默认 false，切最小权限
  variable.tailscale_acl_allow_all = {
    type = "bool";
    default = false;
    description = "Keep the legacy *→* grant while devices are tagged and re-authenticated. Default false = least-privilege ACL.";
  };

  provider.tailscale = {
    tailnet = facts.tailscale.tailnet;
  };

  resource = {
    tailscale_acl.main = {
      # ACL 是静态数据，在 Nix 侧编码；用 Terraform 变量在
      # “打 tag 阶段（保留 *→*）”和“最终阶段（默认拒绝）”之间切换。
      acl = lib.tf.ref "var.tailscale_acl_allow_all ? ${builtins.toJSON aclTaggingJson} : ${builtins.toJSON aclFinalJson}";
    };

    tailscale_dns_preferences.main = {
      magic_dns = true;
    };

    tailscale_service = {
      ninerouter = {
        name = "svc:9router";
        comment = "9router dashboard (HTTP over tailnet)";
        ports = [ "tcp:80" ];
      };

      nezha = {
        name = "svc:nezha";
        comment = "Nezha dashboard (HTTP over tailnet)";
        ports = [ "tcp:80" ];
      };
    };

    # 两个 auth key：VPS 自动带 tag:vps，个人设备自动带 tag:ws。
    # 90 天 reusable；泄露一个只影响一类角色；到期/泄露后 revoke 并轮换该角色 key。
    # 注意：Tailnet Lock 已在 LUC-556 关闭，控制面只依赖 ACL + tagged key。
    # 必须先有 ACL 的 tagOwners，才能创建带 tag 的 key。
    tailscale_tailnet_key.vps_join = {
      reusable = true;
      ephemeral = false;
      preauthorized = false;
      expiry = 7776000;
      tags = [ "tag:vps" ];
      depends_on = [ "tailscale_acl.main" ];
    };

    tailscale_tailnet_key.ws_join = {
      reusable = true;
      ephemeral = false;
      preauthorized = false;
      expiry = 7776000;
      tags = [ "tag:ws" ];
      depends_on = [ "tailscale_acl.main" ];
    };

    # 部分 tag 更新可以直接通过 API 完成；只有移除全部 tag 才需要 reauth。
    # deviceTags 按 hostname 维护每台设备的完整 tag 集合（已去掉 legacy）。
    tailscale_device_tags = lib.mapAttrs' (
      device: cfg:
      lib.nameValuePair (tfName device) {
        device_id = lib.tf.ref "data.tailscale_device.servers[\"${device}\"].id";
        inherit (cfg) tags;
        depends_on = [ "tailscale_acl.main" ];
      }
    ) devices;

    tailscale_device_key.servers = {
      for_each = lib.tf.ref "data.tailscale_device.servers";
      device_id = lib.tf.ref "each.value.id";
      key_expiry_disabled = true;
    };
  };

  data.tailscale_device.servers = {
    # 旧 HCL 对所有设备关闭了 key 过期。terranix 迁移后只保留 dev/agt，
    # 若直接 destroy 旧的 device_key 会在 provider Delete 时重新启用过期
    # （macos-ws 2026-11-25 到期）。把 client 也纳入管理，保持不过期。
    for_each = lib.genAttrs (lib.attrNames devices) (_: true);
    hostname = lib.tf.ref "each.key";
  };

  # 迁移旧 HCL 的 per-device 地址，避免 destroy→create：
  # - device_key 的 Delete 会 SetKey(key_expiry_disabled=false)，重新启用过期；
  # - device_tags 的 Delete 会清空设备 tag，dev 的 svc 服务会出现空 tag 窗口。
  moved = lib.concatMap (device: [
    {
      from = "tailscale_device_key.devices[\"${device}\"]";
      to = "tailscale_device_key.servers[\"${device}\"]";
    }
    {
      from = "tailscale_device_tags.devices[\"${device}\"]";
      to = "tailscale_device_tags.${tfName device}";
    }
  ]) (lib.attrNames devices);

  # 方便把新 key 写入 sops（sensitive output）。
  #   tofu output -raw vps_join_key
  #   tofu output -raw ws_join_key
  output.vps_join_key = {
    value = lib.tf.ref "tailscale_tailnet_key.vps_join.key";
    sensitive = true;
  };

  output.ws_join_key = {
    value = lib.tf.ref "tailscale_tailnet_key.ws_join.key";
    sensitive = true;
  };
}
