{pkgs, ...}: {
  home.packages = with pkgs; [
    (pkgs.go-task.overrideAttrs (oldAttrs: {
      # 移除所有可能的冲突文件，保留 go-task 的功能
      postInstall =
        oldAttrs.postInstall or ""
        + ''
          # 删除所有 shell 补全文件，避免与 taskwarrior 冲突
          rm -rf $out/share/fish/
          rm -rf $out/share/zsh/
          # 保留 bash completion，因为用户使用 bash
        '';
    }))
  ];

  # FIXME

  #   问题原因：
  #  - config.lib.file.mkOutOfStoreSymlink 函数在 NixOS 系统配置中不可用
  #  - 这个函数主要在 Darwin (macOS) 配置中使用
  #
  #  解决方案：
  #  - 移除了 mkOutOfStoreSymlink 函数调用
  #  - 直接使用 Nix 的标准文件引用方式：source = ./taskfile 和 source = ./taskfile/Taskfile.yml
  #  - 添加了 recursive = true 参数以确保目录被正确复制
  #  - 添加了 lib 参数到函数参数列表中
  #
  #  这样修改后，Nix
  #  会直接将文件复制到目标位置，而不是创建符号链接。如果确实需要符号链接，可以考虑在系统激活脚本中使用
  #  ln -s 命令来实现。

  #  home-manager.users.${username} = {
  #    home.file = {
  #      "taskfile" = {
  #        source = ./taskfile;
  #        recursive = true;
  #        onChange = "echo 'Taskfile links updated'";
  #      };
  #      "Taskfile.yml" = {
  #        source = ./taskfile/Taskfile.yml;
  #        onChange = "echo 'Taskfile.yml links updated'";
  #      };
  #    };
  #  };
}
