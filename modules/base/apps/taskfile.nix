{
  pkgs,
  username,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [go-task];

  home-manager.users.${username} = {
    home.file = {
      "taskfile" = {
        source = config.lib.file.mkOutOfStoreSymlink ./taskfile;
        onChange = "echo 'Taskfile links updated'";
      };
      "Taskfile.yml" = {
        source = config.lib.file.mkOutOfStoreSymlink ./taskfile/Taskfile.yml;
        onChange = "echo 'Taskfile.yml links updated'";
      };
    };
  };
}
