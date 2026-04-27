{lib, ...}: {
  # https://mynixos.com/home-manager/options/programs.lazydocker

  # https://github.com/jesseduffield/lazydocker/issues/4#issuecomment-3367900538
  # https://github.com/luisnquin/nixos-config/blob/main/home/modules/programs/development/docker/lazydocker.nix
  # https://github.com/jesseduffield/lazydocker/blob/master/docs/Config.md
  programs.lazydocker = {
    enable = true;
    settings = {
      gui = {
        scrollHeight = 2;
        language = "en";
        theme = {
          activeBorderColor = ["green" "bold"];
          inactiveBorderColor = ["white"];
          optionsTextColor = ["blue"];
        };
        border = "single";

        returnImmediately = true;
        wrapMainPanel = true;
        sidePanelWidth = 0.2;
        showBottomLine = true;
        expandFocusedSidePanel = false;
      };

      logs = {
        timestamps = false;
        since = "60m"; # set to '' to show all logs
        tail = "";
      };

      commandTemplates = {
        dockerCompose = "docker compose";
        restartService = "{{ .DockerCompose }} restart {{ .Service.Name }}";
        up = "{{ .DockerCompose }} up -d";
        down = "{{ .DockerCompose }} down";
        downWithVolumes = "{{ .DockerCompose }} down --volumes";
        upService = "{{ .DockerCompose }} up -d {{ .Service.Name }}";
        startService = "{{ .DockerCompose }} start {{ .Service.Name }}";
        stopService = "{{ .DockerCompose }} stop {{ .Service.Name }}";
        serviceLogs = "{{ .DockerCompose }} logs --since=60m --follow {{ .Service.Name }}";
        viewServiceLogs = "{{ .DockerCompose }} logs --follow {{ .Service.Name }}";
        rebuildService = "{{ .DockerCompose }} up -d --build {{ .Service.Name }}";
        recreateService = "{{ .DockerCompose }} up -d --force-recreate {{ .Service.Name }}";
        allLogs = "{{ .DockerCompose }} logs --tail=300 --follow";
        viewAlLogs = "{{ .DockerCompose }} logs";
        dockerComposeConfig = "{{ .DockerCompose }} config";
        checkDockerComposeConfig = "{{ .DockerCompose }} config --quiet";
        serviceTop = "{{ .DockerCompose }} top {{ .Service.Name }}";
      };

      customCommands = {
        containers = [
          {
            name = "inspect-ip (all containers)";
            attach = true;
            shell = true;

            # docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
            # 查看所有容器IP地址
            command = "docker ps -aq | xargs -r docker inspect | jq -r '.[] | \"\\(.Name) - \\(.NetworkSettings.Networks | to_entries | map(.value.IPAddress) | join(\" \"))\"'";
            serviceNames = [];
          }
          {
            name = "exit-code (selected container)";
            attach = true;
            shell = false;
            # 检查容器退出码
            # docker inspect --format='{{.ExitCode}}' {{.CONTAINER}}
            command = "docker inspect {{ .Container.ID }} | jq -r '.[0].State.ExitCode'";
            serviceNames = [];
          }
          {
            name = "ctop";
            attach = true;
            shell = false;
            command = "ctop";
            serviceNames = [];
          }
          {
            name = "check-mem (selected container)";
            attach = true;
            shell = false;
            command = "docker stats --no-stream --format 'table {{\"{{\"}}.Name{{\"}}\"}}\\t{{\"{{\"}}.MemUsage{{\"}}\"}}\\t{{\"{{\"}}.MemPerc{{\"}}\"}}' {{ .Container.Name }}";
            serviceNames = [];
          }
          {
            name = "check-cpu (selected container)";
            attach = true;
            shell = false;
            command = "docker stats --no-stream --format 'table {{\"{{\"}}.Name{{\"}}\"}}\\t{{\"{{\"}}.CPUPerc{{\"}}\"}}' {{ .Container.Name }}";
            serviceNames = [];
          }
        ];

        images = [
          {
            # 查看镜像构建历史
            name = "image-history (selected image)";
            attach = true;
            shell = false;
            command = "docker history {{ .Image.ID }}";
            serviceNames = [];
          }
          {
            name = "analyze (dive selected image)";
            attach = true;
            shell = false;
            command = "dive {{ .Image.ID }}";
            serviceNames = [];
          }
          {
            name = "verify (selected image size)";
            attach = true;
            shell = true;

            # docker inspect {{.IMAGE_NAME}}:{{.IMAGE_TAG}} --format='{{"{{.Size}}"}}' | numfmt --to=iec
            command = "docker image inspect {{ .Image.ID }} | jq -r '.[0].Size' | numfmt --to=iec";
            serviceNames = [];
          }
        ];
      };

      oS = {
        openCommand = "open {{filename}}";
        openLinkCommand = "open {{link}}";
      };

      stats = {
        graphs = [
          {
            caption = "CPU (%)";
            statPath = "DerivedStats.CPUPercentage";
            color = "blue";
          }
          {
            caption = "Memory (%)";
            statPath = "DerivedStats.MemoryPercentage";
            color = "green";
          }
        ];
      };
    };
  };

  # [Hide project/services panels when not in a docker-compose project · jesseduffield/lazydocker@e3c1c86](https://github.com/jesseduffield/lazydocker/commit/e3c1c8630ae77af0eabca15e00aa270ffbb1d21b) Hide project/services panels when not in a docker-compose project. 按理说应该没问题，但是仍然被识别为应该hide，所以
  programs.zsh.initContent = lib.mkAfter ''
    lzd() {
      local project file

      for file in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
        if [[ -f "$file" ]]; then
          project="$(basename "$PWD")"
          lazydocker -p "$project"
          return
        fi
      done

      lazydocker
    }
  '';
}
