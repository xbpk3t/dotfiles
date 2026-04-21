{
  pkgs,
  mylib,
  ...
}: {
  home.packages = with pkgs;
    [
      # 分类1：质量检查与规范化
      # 用nix的mkOutOfStoreSymlink代替了
      # dotbot

      # https://mynixos.com/nixpkgs/package/pre-commit
      # tags(desc): 代码质量 > 提交钩子 > 自动化
      pre-commit

      # https://mynixos.com/nixpkgs/package/dos2unix
      #
      # [2026-01-24] 遇到了 CRLF 换行符 问题。
      # yamllint 报 wrong new line character: expected \n 期望 LF，但文件是 CRLF。
      # 可以直接用 dos2unix manifests/**/kustomization.yaml 批量解决问题
      # tags(desc): 文本规范化 > 换行修复 > 文件处理
      dos2unix

      # 代码质量和分析
      # tags(desc): 代码质量 > Shell静态检查 > Lint
      shellcheck
      # tags(desc): 代码质量 > 拼写检查 > Lint
      typos
      # tags(desc): 代码质量 > YAML规范 > Lint
      yamllint
      # tags(desc): 代码质量 > Markdown规范 > Lint
      markdownlint-cli

      # https://mynixos.com/nixpkgs/package/api-linter
      # https://mynixos.com/nixpkgs/package/dotenv-linter
      # https://mynixos.com/nixpkgs/package/gitlab-ci-linter

      # https://mynixos.com/nixpkgs/package/kdlfmt
      # kdlfmt 的 pre-commit 仍然需要bin才能使用
      # tags(desc): 代码质量 > 格式化 > KDL
      kdlfmt

      # tags(desc): 代码质量 > URL提取检查 > 文本分析
      urlscan
      # tags(desc): 代码质量 > 链接校验 > 文档检查
      lychee
    ]
    ++ [
      # 分类2：云与 API 工具

      # tags(desc): 云平台 > 隧道代理 > Cloudflare
      cloudflared # cloudflare tunnel

      # https://github.com/cloudflare/workers-sdk
      # https://mynixos.com/nixpkgs/package/wrangler

      # MAYBE: 等cf cli 成熟后，可以用来替代 wrangler
      # https://blog.cloudflare.com/cf-cli-local-explorer/
      # https://www.npmjs.com/package/cf
      # wrangler

      # API 工具
      # tags(desc): API调试 > gRPC > 网络工具
      grpcurl
    ]
    ++ [
      # 分类3：基础系统与文本处理工具

      # 基础工具
      #
      # [2026-01-25]
      # https://mynixos.com/nixpkgs/package/coreutils-prefixed
      # why: For stdbuf/gstdbuf. 需要 stdbuf 来实现 用于并行执行时让日志实时刷新、减少输出延迟/卡住的情况。
      # what: 并不需要 coreutils-prefixed (这个pkg会提供一套 g* 的命令，以与 coreutils 避免冲突)，仅作记录
      #
      # tags(desc): 基础工具 > Unix工具集 > 系统命令
      coreutils

      # tags(desc): 基础工具 > 文件检索 > Unix
      findutils
      # tags(desc): 基础工具 > diff比较 > Unix
      diffutils
      # tags(desc): 基础工具 > 文本处理 > awk
      gawk
      # tags(desc): 基础工具 > 文本处理 > sed
      gnused
      # tags(desc): 基础工具 > 归档打包 > tar
      gnutar
      # tags(desc): 基础工具 > 压缩 > gzip
      gzip

      # 其他实用工具
      # tags(desc): 基础工具 > 监控观察 > 实时刷新
      watch
      # tags(desc): 基础工具 > 文件同步 > 传输
      rsync
    ]
    ++ [
      # 分类4：媒体处理与可视化工具

      # 基础媒体处理
      # tags(desc): 媒体处理 > 视频音频 > 转码
      ffmpeg

      # 音频处理
      # sox
      # lame

      # 图像处理
      # tags(desc): 媒体处理 > 图像编辑 > 转换
      imagemagick

      # cwebp. WebP官方工具
      # https://mynixos.com/nixpkgs/package/libwebp
      # tags(desc): 媒体处理 > 图像编码 > WebP
      libwebp

      # tags(desc): 媒体处理 > 元数据 > 图像信息
      exiftool
      # tags(desc): 可视化 > 图绘制 > 图结构
      graphviz

      # static file server
      # https://mynixos.com/nixpkgs/package/dufs
      # https://github.com/sigoden/dufs
      # https://github.com/cnphpbb/deploy.stack/blob/main/dufs/config/config.yaml ???
      # tags(desc): 文件服务 > 静态分发 > HTTP
      dufs

      # https://mynixos.com/nixpkgs/package/dogdns
      # DNS 查询与诊断工具
      # 'dogdns' has been removed as it is unmaintained upstream and vendors insecure dependencies. Consider switching to 'doggo', a similar tool.
      # dogdns
      # doggo

      # https://mynixos.com/nixpkgs/package/ipcalc
      # 计算子网掩码/网段
      # tags(desc): 网络工具 > IP规划 > 子网计算
      ipcalc
    ];

  imports = mylib.scanPaths ./.;
}
