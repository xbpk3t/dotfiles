{pkgs, ...}: {
  home.packages = with pkgs; [
    taskwarrior3
    taskwarrior-tui
  ];

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;

    # Basic configuration
    config = {
      # Data location
      data.location = "~/.task";

      # Color theme
      color.theme = "dark-256";

      # Default command
      default.command = "next";

      # Date format
      dateformat = {
        "" = "Y-M-D H:N";
        report = "Y-M-D";
        annotation = "Y-M-D H:N";
      };

      # Week starts on Monday
      weekstart = "monday";

      # Display settings
      defaultwidth = 120;
      defaultheight = 40;

      # Search case sensitivity
      search.case.sensitive = false;

      # Confirmation settings
      confirmation = false;

      # Urgency coefficients
      urgency = {
        user.tag.next.coefficient = 15.0;
        due.coefficient = 12.0;
        blocking.coefficient = 8.0;
        priority.coefficient = 6.0;
        active.coefficient = 4.0;
        age.coefficient = 2.0;
        annotations.coefficient = 1.0;
        tags.coefficient = 1.0;
        project.coefficient = 1.0;
      };

      # Report settings
      report = {
        next = {
          columns = "id,start.age,entry.age,depends,priority,project,tags,recur,scheduled.countdown,due.relative,until.remaining,description,urgency";
          labels = "ID,Active,Age,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg";
          sort = "urgency-";
          filter = "status:pending -WAITING";
        };

        list = {
          columns = "id,start.age,entry.age,priority,project,tags,recur.indicator,scheduled.countdown,due,until.remaining,description.count,urgency";
          labels = "ID,Active,Age,P,Project,Tags,R,Sch,Due,Until,Description,Urg";
          sort = "urgency-";
        };

        minimal = {
          columns = "id,project,tags,description.count";
          labels = "ID,Project,Tags,Description";
          sort = "urgency-";
        };
      };

      # Context definitions
      context = {
        work = {
          read = "+work";
          write = "+work";
        };
        personal = {
          read = "+personal";
          write = "+personal";
        };
      };

      # UDA (User Defined Attributes)
      uda = {
        reviewed = {
          type = "date";
          label = "Reviewed";
        };
        estimate = {
          type = "numeric";
          label = "Estimate";
        };
      };
    };
  };

  #     programs = {
  #      taskwarrior = {
  #        enable = true;
  #        package  = pkgs.taskwarrior3;
  #        colorTheme = "light-256";
  #        config = {
  #          urgency = {
  #            uda.priority = {
  #              L.coefficient = -1.0;
  #              M.coefficient = 5; # + 1.1
  #              H.coefficient = 10; # + 4
  #            };
  #            user.tag."in".coefficient = 30;
  #          };
  #          uda.details = {
  #            type = "string";
  #            label = "Details";
  #          };
  #          report = {
  #            next.filter = "-chase -WAITING status:pending limit:page";
  #            chase = {
  #              description = "Tasks to chase up";
  #              columns = "id,start.age,entry.age,depends,priority,project,recur,scheduled.countdown,due.relative,until.remaining,description,urgency";
  #              filter = "+chase -WAITING status:pending limit:page";
  #              labels = "ID,Active,Age,Deps,P,Project,Recur,S,Due,Until,Description,Urg";
  #              sort = "urgency-";
  #            };
  #          };
  #        };
  #      };
  #
  #      bash.shellAliases = {
  #        "in" = "clear; task add +in";
  #        next = "clear; task add +next";
  #        tasks = "task sync ; task";
  #      };
  #    };
}
