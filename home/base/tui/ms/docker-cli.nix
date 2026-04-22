{pkgs, ...}: {
  # Colima 本身负责创建和管理 docker context，这里只负责声明式启用默认 profile。
  # https://mynixos.com/home-manager/options/programs.docker-cli
  programs.docker-cli = {
    enable = true;

    #  - aliases — 如果你经常手敲 docker 命令，加几个常用的能省不少时间；如果只是偶尔用，意义不大。纯粹看个人习惯。
    #  - detachKeys — 默认 ctrl-p,ctrl-q 已经够用，除非你遇到快捷键冲突（比如 tmux 里），否则不需要改。
    #  - credHelpers — 你已经用了 credsStore = "osxkeychain"，它会统一处理所有 registry 的凭证。credHelpers 只在你需要按 registry 用不同 helper 时才需要（比如 AWS ECR 用 ecr-login），否则多余。
    settings = {
      # 保持 currentContext 为 colima（Colima 启动时会自动设置，但声明式更保险）
      currentContext = "colima";

      # 如果你有其他全局配置，也可以加在这里
      # 例如：
      features = {
        # 注意应该是字符串，否则会报错 json: cannot unmarshal bool into Go struct field ConfigFile.features of type string
        buildkit = "true";
      };

      # 这里用 credsStore 代替 auths
      # macOS 上推荐用 keychain
      credsStore = "osxkeychain";
    };
  };

  home.packages = with pkgs;
    [
      # Docker 基础 CLI
      # https://mynixos.com/nixpkgs/package/docker
      # https://github.com/docker/cli
      docker

      # https://mynixos.com/nixpkgs/package/docker-credential-helpers
      # https://github.com/docker/docker-credential-helpers
      # 否则会报 osxkeychain not found
      docker-credential-helpers
    ]
    ++ [
      # 日常 CLI / TUI 操作

      # 容器版 top
      # https://mynixos.com/nixpkgs/package/ctop
      # https://github.com/bcicen/ctop
      ctop
    ]
    ++ [
      # 镜像分析 / 瘦身

      # 分析镜像层结构
      # 看镜像每一层内容、缩小image，非常经典
      # https://mynixos.com/nixpkgs/package/dive
      # https://github.com/wagoodman/dive
      # dive {{.IMAGE_NAME}}:{{.IMAGE_TAG}}
      dive

      # 优化Image大小
      # 主打 inspect / optimize / debug / minify 容器镜像，命令面很宽，定位很像“容器优化工具箱”。它还明确提到有 xray、lint、build、debug、run、images、merge、registry、vulnerability 等命令。
      # https://mynixos.com/nixpkgs/package/docker-slim
      # https://github.com/slimtoolkit/slim
      # [2026-04-22] slim可以上位替代 https://github.com/goldmann/docker-squash 因为
      ## 1、slim 使用了更高级的技术：动态探测 (Dynamic Analysis)。它会启动你的容器，监控哪些文件被真的调用了，然后把没用的（比如包管理器、文档、不常用的库）全部剔除。
      ## 2、替代逻辑： docker-squash 顶多能把 1GB 变成 800MB，而 slim 能把 1GB 变成 50MB。从优化量级上完全不是一个层面的工具。
      # slim build --target {{.IMAGE_NAME}}:{{.IMAGE_TAG}} --tag {{.IMAGE_NAME}}:slim-{{.IMAGE_TAG}}
      docker-slim
    ]
    ++ [
      # Dockerfile / 供应链安全

      # Dockerfile linter，适合把 Dockerfile 质量门禁前置
      # https://mynixos.com/nixpkgs/package/hadolint
      # https://github.com/hadolint/hadolint
      # hadolint Dockerfile
      hadolint

      # Image 安全漏洞扫描
      # docker 的镜像安全检测工具，查找 docker 容器、k8s 中是否有错误配置、密钥、SBOM 以及漏洞。（desktop 内置了，但是这个看起来更直观）, better than quay/clair and anchore/grype
      # https://github.com/owenrumney/lazytrivy
      # https://mynixos.com/nixpkgs/package/lazytrivy
      # https://mynixos.com/nixpkgs/package/trivy
      # trivy image --ignore-unfixed --severity CRITICAL {{.IMAGE_NAME}}:{{.IMAGE_TAG}}
      trivy

      # 给镜像和文件系统生 SBOM
      # https://mynixos.com/nixpkgs/package/syft
      # https://github.com/anchore/syft
      syft

      # 扫镜像和文件系统漏洞
      # https://mynixos.com/nixpkgs/package/grype
      # https://github.com/anchore/grype
      grype

      # https://mynixos.com/nixpkgs/package/docker-sbom
      # https://github.com/docker/sbom-cli-plugin
      docker-sbom

      # Docker Scout：如果你更想走官方路线，Scout 已经把 SBOM、CVE、recommendations、policy 等都收进 docker scout 命令体系了
      # docker scout: 当前 nixpkgs 暂无独立 docker-scout 包，先不添加。
    ];

  home.shellAliases = {
    # 注意 runlike 和 docker-autocompose 都是在宿主机（而非container内）执行的cli工具，但是这两个都没有nixpkgs，都给出了 pipx 和 docker 两种usage方案，这里我们选择前者，并换成uvx
    # 这两个工具搭配工作，前者适用于单个container，直接拿到 docker run。后者则针对 project，拿到 compose，需要落盘后才能运行
    # 所以它俩不是互斥关系，而是很适合串起来用：先用 runlike 救火，再用 docker-autocompose 把活下来的实例收编成 Compose。这个组合在你那个“BPF、mount 多、env 多、命令很长”的场景里尤其合理。

    # https://github.com/lavie/runlike
    # 类似chrome 之于 copy as curl，用来一键生成非常复杂的docker run命令。快速获取 Docker 容器启动命令的工具。这是一个用于解析运行中容器的工具，可自动生成对应的 docker run 启动命令。它能够提取容器的配置信息，包括端口绑定、映射卷、环境变量、网络设置等，适用于复制、调试或迁移容器的场景。 # 具体情况如下，事情要从上周的一次事故说起，我们用 docker 部署的程序有一点问题，要马上回滚到上一个版本。这个 docker 是一个比较复杂的和 BPF 有关的程序，启动时候需要设置很多 mount 和 environments，docker run 的命令特别长。所以我用 Ansible 来配置好这些变量，然后启动 docker，一个实例要花费 3～5 分钟才能启动。同事突然说，某实例他手动启动了，当时我就震惊了，怎么手速这么快？！请教了一下，原来是用的 runlike 工具。这个工具的原理是，`docker inspect <container-name> | runlike --stdin` ，就会生成这个容器的 docker run 命令。
    runlike = "uvx runlike";

    # https://github.com/Red5d/docker-autocompose
    # 快速生成 docker-compose.yaml (收编/迁移)
    # docker-autocompose 的目标是吐出 Compose YAML，而且可以把多个容器一起转出来
    # 注意：uvx 后接的是 PyPI 上的包名 "docker-autocompose"
    autocompose = "uvx --from docker-autocompose autocompose";
  };
}
