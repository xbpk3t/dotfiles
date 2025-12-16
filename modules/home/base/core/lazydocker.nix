{...}: {
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
        dockerCompose = "docker-compose";
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
}
