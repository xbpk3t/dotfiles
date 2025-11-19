# { ... }: {
#   programs.lazydocker = {
#     enable = true;
#     settings = {
#       gui = {
#         language = "en"; # currently no russian
#         border = "rounded";
#
#         nerdFontsVersion = "3";
#         showCommandLog = false;
#         showFileTree = true;
#       };
#
#             commandTemplates.dockerCompose = "docker compose";
#
#       # gui = {
#       #   border = "single";
#       #   returnImmediately = true;
#       #   sidePanelWidth = 0.2;
#       #   theme = {
#       #     activeBorderColor = [
#       #       "#cba6f7"
#       #       "bold"
#       #     ];
#       #     inactiveBorderColor = [
#       #       "#a6adc8"
#       #     ];
#       #     optionsTextColor = [
#       #       "#89b4fa"
#       #     ];
#       #     selectedLineBgColor = [
#       #       "#313244"
#       #     ];
#       #   };
#       # };
#
#
#
#       # settings = {
#     #   commandTemplates = rec {
#     #     dockerCompose = "docker compose";
#     #     restartService = "${dockerCompose} restart {{ .Service.Name }}";
#     #     up =  "${dockerCompose} up -d";
#     #     down = "${dockerCompose} down";
#     #     downWithVolumes = "${dockerCompose} down --volumes";
#     #     upService =  "${dockerCompose} up -d {{ .Service.Name }}";
#     #     startService = "${dockerCompose} start {{ .Service.Name }}";
#     #     stopService = "${dockerCompose} stop {{ .Service.Name }}";
#     #     serviceLogs = "${dockerCompose} logs --since=60m --follow {{ .Service.Name }}";
#     #     viewServiceLogs = "${dockerCompose} logs --follow {{ .Service.Name }}";
#     #     rebuildService = "${dockerCompose} up -d --build {{ .Service.Name }}";
#     #     recreateService = "${dockerCompose} up -d --force-recreate {{ .Service.Name }}";
#     #     allLogs = "${dockerCompose} logs --tail=300 --follow";
#     #     viewAlLogs = "${dockerCompose} logs";
#     #     dockerComposeConfig = "${dockerCompose} config";
#     #     checkDockerComposeConfig = "${dockerCompose} config --quiet";
#     #     serviceTop = "${dockerCompose} top {{ .Service.Name }}";
#     #   };
#     # };
#     };
#   };
# }
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
        returnImmediately = true;
        wrapMainPanel = true;
        sidePanelWidth = 0.333;
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
