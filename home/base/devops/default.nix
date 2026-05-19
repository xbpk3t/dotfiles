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
      #
      ## 功能：列出目标地址上所有可用的 gRPC 服务
      ## 示例：grpcurl localhost:50051 list
      #- 'grpcurl {{.TARGET}} list'
      #
      ## 功能：查看指定服务或消息类型的完整定义（proto 描述）
      ## 示例：grpcurl localhost:50051 describe helloworld.Greeter
      #- 'grpcurl {{.TARGET}} describe {{.SERVICE}}'
      #
      ## 功能：直接调用某个 gRPC 方法，以 JSON 格式传入请求体
      ## 示例：grpcurl -d '{"name":"World"}' localhost:50051 helloworld.Greeter/SayHello
      #- "grpcurl -d '{{.DATA}}' {{.TARGET}} {{.METHOD}}"
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
      #- rsync [选项] 源路径 目标路径 # 基本语法
      #- rsync /source/ /destination/ # 同步目录，不保留属性
      #- rsync -a /source/ /destination/ # 保留文件属性
      #- rsync -av /source/ /destination/ # 详细输出并保留属性
      #- rsync -av --progress /source/ /destination/ # 显示进度
      #- rsync -av -e "ssh -p 2222" /local/ username@hostname:/remote/ # 指定 SSH 端口
      #- rsync -av -e "ssh -i ~/.ssh/mykey.pem" /local/ username@hostname:/remote/ # 指定私钥
      #- rsync -av --delete --progress /local username@hostname:/remote/ # 远程同步并删除目标端多余文件
      #- rsync -av --exclude='*.tmp' --exclude='cache/' /source/ /backup/ # 排除临时文件和缓存目录
      #- rsync -av --exclude-from='exclude-list.txt' /source/ /backup/ # 使用排除文件
      #- rsync -avP --partial large-video.mp4 username@hostname:/videos/ # 断点续传大文件
      #- rsync -avz --delete --progress -e "ssh -o StrictHostKeyChecking=no" /Users/luck/Desktop/nix-config/ luck@192.168.71.7:~/Desktop/nix-config/ # 同步本机 nix-config 到远端
      #- rsync -avzP /local/dir/ user@remote:/remote/dir/ # 本机同步目录内容到远端
      #- rsync -avzP user@remote:/remote/dir/ /local/dir/ # 远端同步目录内容到本机
      #- rsync -avzP -e ssh user@hostA:/path/file user@hostB:/path/ # 远端 A 同步文件到远端 B
      #- rsync -avzP -e "ssh -p 2222 -i ~/.ssh/id_ed25519" /local/dir/ user@remote:/remote/dir/ # 指定 SSH 端口和私钥
      #- rsync -avzP --delete /src/ user@remote:/dst/ # 删除目标端多余文件，让目标镜像源
      #- rsync -avzP --exclude '*.log' --exclude node_modules/ /src/ user@remote:/dst/ # 排除日志和 node_modules
      #- rsync -avzP --dry-run /src/ user@remote:/dst/ # 演练，不真正执行
      #- rsync -avzP --bwlimit=20m /src/ user@remote:/dst/ # 限速同步
      #- rsync -avzP --rsync-path="sudo rsync" /local/file user@remote:/protected/path/ # 远端使用 sudo 写入受保护目录
      #- rsync -avz --delete --progress -e # taskfile 中的不完整命令
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
