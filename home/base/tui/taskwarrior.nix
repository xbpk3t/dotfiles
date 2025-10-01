{pkgs, ...}: {
  home.packages = with pkgs; [
    taskwarrior-tui

    # 重命名 taskwarrior 的二进制文件为 tz，避免与 go-task 冲突
    # [Conflict name with go-task's task runner executable. · Issue #3463 · GothenburgBitFactory/taskwarrior](https://github.com/GothenburgBitFactory/taskwarrior/issues/3463)
    (pkgs.taskwarrior3.overrideAttrs (oldAttrs: {
      postInstall =
        oldAttrs.postInstall or ""
        + ''
          # 重命名二进制文件
          mv $out/bin/task $out/bin/tz

          # 处理 bash completion 冲突 - 删除 taskwarrior 的 completion，让 go-task 的生效
          rm -f $out/share/bash-completion/completions/task.bash

          # 删除所有可能的冲突文件，确保与 go-task 无冲突
          rm -rf $out/share/fish/
          rm -rf $out/share/zsh/
          rm -rf $out/share/bash-completion/
        '';

      # 禁用版本检查，因为二进制文件已被重命名
      doInstallCheck = false;
    }))
  ];

  # 生成 taskwarrior 配置文件
  home.file.".taskrc" = {
    text = ''
      # Data location
      data.location=~/.task

      # Color theme
      # color.theme=dark-256

      # Default command
      default.command=next

      # Date format
      dateformat=Y-M-D H:N
      dateformat.report=Y-M-D
      dateformat.annotation=Y-M-D H:N

      # Week starts on Monday
      weekstart=monday

      # Display settings
      defaultwidth=120
      defaultheight=40

      # Search case sensitivity
      search.case.sensitive=no

      # Confirmation settings
      confirmation=no

      # Urgency coefficients
      urgency.user.tag.next.coefficient=15.0
      urgency.due.coefficient=12.0
      urgency.blocking.coefficient=8.0
      urgency.priority.coefficient=6.0
      urgency.active.coefficient=4.0
      urgency.age.coefficient=2.0
      urgency.annotations.coefficient=1.0
      urgency.tags.coefficient=1.0
      urgency.project.coefficient=1.0

      # Report settings
      report.next.columns=id,start.age,entry.age,depends,priority,project,tags,recur,scheduled.countdown,due.relative,until.remaining,description,urgency
      report.next.labels=ID,Active,Age,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg
      report.next.sort=urgency-
      report.next.filter=status:pending -WAITING

      report.list.columns=id,start.age,entry.age,priority,project,tags,recur.indicator,scheduled.countdown,due,until.remaining,description.count,urgency
      report.list.labels=ID,Active,Age,P,Project,Tags,R,Sch,Due,Until,Description,Urg
      report.list.sort=urgency-

      report.minimal.columns=id,project,tags,description.count
      report.minimal.labels=ID,Project,Tags,Description
      report.minimal.sort=urgency-

      # Context definitions
      context.work.read=+work
      context.work.write=+work
      context.personal.read=+personal
      context.personal.write=+personal

      # UDA (User Defined Attributes)
      uda.reviewed.type=date
      uda.reviewed.label=Reviewed
      uda.estimate.type=numeric
      uda.estimate.label=Estimate
    '';
  };
}
