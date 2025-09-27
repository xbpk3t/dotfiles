_: {
  programs.pandoc = {
    enable = true;

    # 默认设置
    defaults = {
      # 默认元数据
      metadata = {
        author = "XBPk3T";
        lang = "zh-CN";
      };

      # PDF 引擎设置
      pdf-engine = "xelatex";

      # 默认输出格式
      # to = "html5";

      # 模板设置
      # template = "default";

      # 变量设置
      variables = {
        # 几何设置（页边距）
        geometry = "margin=1in";
        # 字体设置
        mainfont = "Times New Roman";
        # 中文字体
        CJKmainfont = "SimSun";
        # 行间距
        linestretch = "1.25";
      };

      # 过滤器
      filters = [
        # "pandoc-crossref"  # 交叉引用
        # "pandoc-citeproc"  # 引用处理
      ];

      # 输出选项
      standalone = true;
      table-of-contents = true;
      toc-depth = 3;
      number-sections = true;

      # HTML 特定选项
      html-q-tags = true;

      # LaTeX 特定选项
      # latex-engine = "xelatex";
    };

    # 引用样式数据库路径
    # citationStyles = {};
  };

  # 添加常用的 pandoc 别名
  programs.bash.shellAliases = {
    #    # Markdown 转 HTML
    #    md2html = "pandoc -f markdown -t html5 -o";
    #    # Markdown 转 PDF
    #    md2pdf = "pandoc -f markdown -t pdf -o";
    #    # Markdown 转 Word
    #    md2docx = "pandoc -f markdown -t docx -o";
    #    # HTML 转 Markdown
    #    html2md = "pandoc -f html -t markdown -o";
  };
}
