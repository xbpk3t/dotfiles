_: {
  programs.ripgrep = {
    enable = true;

    # 配置参数
    arguments = [
      # 智能大小写匹配
      "--smart-case"
      # 显示行号
      "--line-number"
      # 显示列号
      "--column"
      # 不显示标题
      "--no-heading"
      # 颜色输出
      "--color=always"
      # 最大列宽（避免过长行）
      "--max-columns=300"
      # 用来 conjunction with --max-columns, 即使超出也preview前面的部分
      "--max-columns-preview"
      # 最大文件大小（避免二进制文件）
      "--max-filesize=10M"
    ];
  };

  # 添加 ripgrep 别名到 shell
  programs.zsh.shellAliases = {
    #    # 搜索时包含隐藏文件
    #    rgh = "rg --hidden";
    #    # 只搜索文件名
    #    rgf = "rg --files | rg";
    #    # 搜索并显示上下文
    #    rgc = "rg -C 3";
    #    # 搜索特定文件类型
    #    rgjs = "rg -t js";
    #    rggo = "rg -t go";
    #    rgpy = "rg -t py";
    #    rgmd = "rg -t md";
    #    # 统计匹配数
    #    rgcount = "rg -c";
    #    # 只显示匹配的文件名
    #    rgfiles = "rg -l";
  };
}
