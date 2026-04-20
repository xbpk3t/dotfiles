{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://github.com/microsoft/markitdown
    # 把 microsoft office文档转成md
    # [2026-04-03] 感觉还是比 markit 要好用
    # python313Packages.markitdown

    # https://github.com/DS4SD/docling
    # Easy Scraper是不是就使用这个实现的？支持读取多种流行的文档格式（PDF、DOCX、PPTX、图像、HTML 等）并出为 Markdown 和 JSON。具备先进的 PDF 理解能力，包括页面布局、阅读顺序及表格结构。提供统一且表达丰富 DoclingDocument 表示格式。能够提取元数据，如标题、作者及语言等信息。
    # docling

    # https://github.com/yshavit/mdq
    # like jq but for Markdown, find specific elements in a md doc
    # mdq

    # https://mynixos.com/nixpkgs/package/doxx
    # https://github.com/bgreenwell/doxx
    doxx
  ];
}
