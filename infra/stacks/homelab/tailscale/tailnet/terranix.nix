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

  # 自定义 DERP region 全部下线（保留默认 region 即可）：
  #   901 (la) / 903 (cn-sh) 因 dev(LA) → agt(SH) 公网 TCP 被 GFW 挡、而 Mac 会优先
  #   选 cn-sh 作为 home DERP，导致 Mac↔dev 单向，已移除（见 f68eb73d）。
  #   902 (hk-2, 47.79.17.202) 已不可达：hermes `tailscale debug derp hk-2` TCP 超时，
  #   Mac/hermes netcheck 里也没有该 region 的延迟。
  # Mac（对称 NAT）↔ hermes 打洞失败改用 peer relay（agt UDP 40000），
  # 不再依赖自定义 DERP region。

  acl = {
    # Tailscale Services 要求 service host 是 tagged device。
    tagOwners = {
      # Tailscale 不允许通过 API 给 tagged node 摘 tag（需要 reauth），
      # 所以迁移保留设备上的旧 tag；grant 已改为 IP 规则，不依赖它们。
      "tag:exit" = [ "xbpk3t@github" ];
      "tag:ssh" = [ "xbpk3t@github" ];
      "tag:svc" = [ "xbpk3t@github" ];
      "tag:svc-9router" = [ "xbpk3t@github" ];
      "tag:vps" = [ "xbpk3t@github" ];
      "tag:ws" = [ "xbpk3t@github" ];
    };

    grants = [
      {
        src = [ "*" ];
        dst = [ "*" ];
        ip = [ "*" ];
      }
      # 手机 exit node：xbpk3t@nod-am 是早已不存在的用户（tailnet 现在只有
      # xbpk3t@github），旧规则匹配不到任何设备。改用手机 tailnet IP。
      {
        src = [ "100.123.207.1" ]; # Redmi Note 13 Pro
        dst = [ "autogroup:internet" ];
        ip = [ "*" ];
      }
      # hm PA local-build exit node: the PA uses nixos-vps-dev only while
      # building the HM generation (GitHub flake inputs). It clears the exit
      # node afterwards. autoApprovers already approves the dev exit node; this
      # grant is the missing client-side permission. src 必须是身份或 IP：
      # user@hostname 不是合法选择器（只有 hosts 别名可用于 dst）。
      {
        src = [ "100.72.194.36" ]; # hermes-wb (hm PA)
        dst = [ "autogroup:internet" ];
        ip = [ "*" ];
      }
      # peer relay：只允许 Mac(100.87.216.84) 和 hermes(100.72.194.36) 用 agt
      # (100.66.22.92) 做 UDP 中继。两者都在 NAT 后，Mac 侧还是对称 NAT，直连打洞
      # 失败；DERP 又会绕美国。grant 的 src 是"需要通过 relay 访问的设备"，
      # 两端都列入，保证两个方向都能命中。能力本身不需要参数。
      # 注意：src 用 Tailscale IP；直接写 hostname 会被控制面拒绝
      # （invalid address），除非在 ACL 的 hosts 里额外定义别名。
      {
        src = [
          "100.87.216.84" # macos-ws
          "100.72.194.36" # hermes-wb
        ];
        dst = [ "100.66.22.92" ]; # nixos-vps-agt
        app = {
          "tailscale.com/cap/relay" = [ ];
        };
      }
    ];

    autoApprovers = {
      exitNode = [
        "xbpk3t@github"
        "tag:svc-9router"
      ];
      routes = {
        "0.0.0.0/0" = [
          "xbpk3t@github"
          "tag:svc-9router"
        ];
        "::/0" = [
          "xbpk3t@github"
          "tag:svc-9router"
        ];
      };
      services = {
        "svc:9router" = [ "tag:svc-9router" ];
        "svc:nezha" = [ "tag:svc-9router" ];
      };
    };

    ssh = [
      # 内层 workstation（tag:ws，含 Mac）→ 外层 VPS（tag:ssh）：Tailscale
      # SSH 由 ssh 段裁决，不走 grants。tagged 设备不属于 autogroup:self，
      # 必须显式列出 tag:ws / tag:vps；但 check 不支持 tag src，只能用 accept。
      {
        action = "accept";
        src = [
          "tag:ws"
          "tag:vps"
        ];
        dst = [ "tag:ssh" ];
        users = [ "luck" ];
      }
      # 非 tagged 用户设备的入口保留 check（周期重新认证）。
      {
        action = "check";
        src = [ "xbpk3t@github" ];
        dst = [ "tag:ssh" ];
        users = [ "luck" ];
      }
      {
        action = "check";
        src = [ "autogroup:member" ];
        dst = [ "autogroup:self" ];
        users = [
          "autogroup:nonroot"
          "root"
        ];
      }
    ];
  };
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

  provider.tailscale = {
    tailnet = facts.tailscale.tailnet;
  };

  resource = {
    tailscale_acl.main = {
      # ACL 是静态数据，直接在 Nix 侧编码；不使用自定义 derpMap（默认 region 即可）。
      acl = builtins.toJSON acl;
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

    tailscale_tailnet_key.device_join = {
      reusable = true;
      ephemeral = false;
      preauthorized = false;
      expiry = 7776000;
    };

    tailscale_device_tags = {
      nixos_vps_dev = {
        device_id = lib.tf.ref "data.tailscale_device.servers[\"nixos-vps-dev\"].id";
        # 旧 tag 不能通过 API 摘除（需要 reauth）；保留并补上服务 tag。
        tags = [
          "tag:exit"
          "tag:svc"
          "tag:svc-9router"
          "tag:vps"
        ];
        depends_on = [ "tailscale_acl.main" ];
      };

      hermes_wb = {
        device_id = lib.tf.ref "data.tailscale_device.servers[\"hermes-wb\"].id";
        tags = [ "tag:vps" ];
        depends_on = [ "tailscale_acl.main" ];
      };

      macos_ws = {
        device_id = lib.tf.ref "data.tailscale_device.servers[\"macos-ws\"].id";
        tags = [ "tag:ws" ];
        depends_on = [ "tailscale_acl.main" ];
      };

      nixos_vps_agt = {
        device_id = lib.tf.ref "data.tailscale_device.servers[\"nixos-vps-agt\"].id";
        tags = [
          "tag:ssh"
          "tag:vps"
        ];
        depends_on = [ "tailscale_acl.main" ];
      };

      nixos_wsl = {
        device_id = lib.tf.ref "data.tailscale_device.servers[\"nixos-wsl\"].id";
        tags = [ "tag:ws" ];
        depends_on = [ "tailscale_acl.main" ];
      };
    };

    tailscale_device_key.servers = {
      for_each = lib.tf.ref "data.tailscale_device.servers";
      device_id = lib.tf.ref "each.value.id";
      key_expiry_disabled = true;
    };
  };

  data.tailscale_device.servers = {
    for_each = {
      "nixos-vps-dev" = true;
      "nixos-vps-agt" = true;
      # 旧 HCL 对所有设备关闭了 key 过期。terranix 迁移后只保留 dev/agt，
      # 若直接 destroy 旧的 device_key 会在 provider Delete 时重新启用过期
      # （macos-ws 2026-11-25 到期）。把 client 也纳入管理，保持不过期。
      "macos-ws" = true;
      "nixos-wsl" = true;
      "hermes-wb" = true;
    };
    hostname = lib.tf.ref "each.key";
  };

  # 迁移旧 HCL 的 per-device 地址，避免 destroy→create：
  # - device_key 的 Delete 会 SetKey(key_expiry_disabled=false)，重新启用过期；
  # - device_tags 的 Delete 会清空设备 tag，dev 的 svc 服务会出现空 tag 窗口。
  moved = [
    {
      from = "tailscale_device_key.devices[\"hermes-wb\"]";
      to = "tailscale_device_key.servers[\"hermes-wb\"]";
    }
    {
      from = "tailscale_device_key.devices[\"macos-ws\"]";
      to = "tailscale_device_key.servers[\"macos-ws\"]";
    }
    {
      from = "tailscale_device_key.devices[\"nixos-vps-agt\"]";
      to = "tailscale_device_key.servers[\"nixos-vps-agt\"]";
    }
    {
      from = "tailscale_device_key.devices[\"nixos-vps-dev\"]";
      to = "tailscale_device_key.servers[\"nixos-vps-dev\"]";
    }
    {
      from = "tailscale_device_key.devices[\"nixos-wsl\"]";
      to = "tailscale_device_key.servers[\"nixos-wsl\"]";
    }
    {
      from = "tailscale_device_tags.devices[\"nixos-vps-dev\"]";
      to = "tailscale_device_tags.nixos_vps_dev";
    }
    {
      from = "tailscale_device_tags.devices[\"hermes-wb\"]";
      to = "tailscale_device_tags.hermes_wb";
    }
    {
      from = "tailscale_device_tags.devices[\"macos-ws\"]";
      to = "tailscale_device_tags.macos_ws";
    }
    {
      from = "tailscale_device_tags.devices[\"nixos-vps-agt\"]";
      to = "tailscale_device_tags.nixos_vps_agt";
    }
    {
      from = "tailscale_device_tags.devices[\"nixos-wsl\"]";
      to = "tailscale_device_tags.nixos_wsl";
    }
  ];
}
