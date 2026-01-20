# 无法完全移植 IDEA/GoLand 的 Monokai 颜色方案的原因（误差来源）：
# 1) 语义层级不同：.icls 有大量语言/语义细分项，Zed 只有通用 Tree-sitter 分类，无法一一对应。
# 2) 渲染能力不同：.icls 支持背景/下划线/错误条纹等效果，Zed 主题字段并不完全覆盖。
# 3) 字段缺失与语义差异：部分项在 Zed 中没有对应键（如选区、光标/匹配细分），只能近似处理。
#
# Markdown fenced code block 背景需求说明：
# 1) 需求：在 Markdown 的 fenced code block 里，实现“整块矩形淡绿色背景”（含空白与行尾到右边界），类似 IDEA。
# 2) 为什么无法在 Zed 里实现：Zed 主题只能给 Tree-sitter 的 capture（syntax token）设置颜色/背景；Markdown 的 code block
#    内容被注入为目标语言的 token（如 string/property/punctuation），JSON 里没有“code block 容器”这类 capture，
#    因此无法对“整块 block”上背景，只能对文字 token 上背景。
# 3) 妥协方案与实现：
#    - 方案 A（全局影响，最简单）：在 theme 的 syntax.<capture> 上加 background_color（如 string/property/keyword/punctuation 等），
#      代价是所有文件都会受影响，不仅是 Markdown code block。
#    - 方案 B（仅限 Markdown，成本高）：自建/覆盖 Markdown language extension，在 highlights.scm 给 code_fence_content 打专用 capture
#      （例如 @markup.raw.block），再在 theme 里只对该 capture 设置 background_color；仍然只能给文字 token 上底色，无法铺满整块。
#
#
# 也可以选择直接用 theme-overrides，但是我懒得再安装拓展，所以直接自己创建theme
# https://zed.dev/docs/themes#theme-overrides
#
#
#
# 暂未处理：
#
#   - 选区颜色：Zed v0.2.0 schema 里没有 editor.selection 之类字段（只有 players[].selection），无法对齐 iCLS 的 SELECTION_BACKGROUND = #575959
# - 光标颜色：schema 没有独立 caret 字段（只有 players[].cursor），无法直接映射 CARET_COLOR = #F8F8F0
# - 未匹配括号背景：只有 editor.document_highlight.bracket_background，没有 unmatched 对应字段，UNMATCHED_BRACE_ATTRIBUTES = #583535 暂不可设
# - Console Cyan：iCLS 值是 #6b8b8（位数异常，疑似 typo），因此我保留现有 terminal.ansi.cyan/bright_cyan
# - Console System/User Input：CONSOLE_SYSTEM_OUTPUT、CONSOLE_USER_INPUT 在 ANSI 里没有明确一一对应项，暂未映射
#
#
{
  "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";

  # https://github.com/slymax/zedokai
  name = "Monokai";
  author = "lucas";
  themes = [
    {
      name = "Monokai-Z";
      appearance = "dark";
      style = {
        background = "#272822";
        "background.appearance" = "opaque";
        border = "#131310";
        "border.disabled" = "#161613";
        "border.focused" = "#6e7066";
        "border.selected" = "#161613";
        "border.transparent" = "#161613";
        "border.variant" = "#131310";
        conflict = "#fd971f";
        created = "#a6e22e";
        deleted = "#f92672";
        "drop_target.background" = "#161613bf";
        # 对齐 IDEA CARET_ROW_COLOR = #3E3D32（Zed 支持活动行背景）
        # "editor.active_line.background" = "#fdfff10c";
        "editor.active_line.background" = "#3e3d32";
        "editor.active_line_number" = "#fdfff1";
        # 对齐 IDEA INDENT_GUIDE / SELECTED_INDENT_GUIDE = #464741
        # "editor.active_wrap_guide" = "#161613";
        "editor.active_wrap_guide" = "#464741";
        "editor.background" = "#272822";
        # 对齐 IDEA IDENTIFIER_UNDER_CARET_ATTRIBUTES 背景 = #3C3C57
        # "editor.document_highlight.read_background" = "#3d3e38";
        "editor.document_highlight.read_background" = "#3c3c57";
        # 对齐 IDEA WRITE_IDENTIFIER_UNDER_CARET_ATTRIBUTES 背景 = #472C47
        "editor.document_highlight.write_background" = "#472c47";
        # 对齐 IDEA MATCHED_BRACE_ATTRIBUTES 背景 = #3A6DA0
        "editor.document_highlight.bracket_background" = "#3a6da0";
        # 对齐 IDEA TEXT 前景色（#f8f8f2）
        # "editor.foreground" = "#fdfff1";
        "editor.foreground" = "#f8f8f2";
        "editor.gutter.background" = "#272822";
        # 对齐 IDEA LINE_NUMBERS_COLOR = #F8F8F2
        # "editor.line_number" = "#57584f";
        "editor.line_number" = "#f8f8f2";
        "editor.subheader.background" = "#20211c";
        # 对齐 IDEA INDENT_GUIDE / WHITESPACES = #464741
        # "editor.wrap_guide" = "#131310";
        "editor.wrap_guide" = "#464741";
        # 对齐 IDEA INDENT_GUIDE = #464741
        "editor.indent_guide" = "#464741";
        # 对齐 IDEA SELECTED_INDENT_GUIDE = #464741（无单独色则与普通一致）
        "editor.indent_guide_active" = "#464741";
        # 对齐 IDEA WHITESPACES = #464741
        "editor.invisible" = "#464741";
        "element.background" = "#3b3c35";
        "element.hover" = "#20211c";
        "element.selected" = "#fdfff10c";
        "elevated_surface.background" = "#20211c";
        error = "#f92672";
        "error.background" = "#20211c";
        "error.border" = "#131310";
        "ghost_element.hover" = "#fdfff10c";
        "ghost_element.selected" = "#fdfff10c";
        hidden = "#919288";
        hint = "#919288";
        "hint.background" = "#20211c";
        "hint.border" = "#131310";
        ignored = "#57584f";
        info = "#e6db74";
        "info.background" = "#20211c";
        "info.border" = "#131310";
        "link_text.hover" = "#fdfff1";
        modified = "#fd971f";
        "pane_group.border" = "#131310";
        "panel.background" = "#20211c";
        "panel.focused_border" = "#ffffff20";
        players = [
          {
            background = "#fdfff1";
            cursor = "#fdfff1";
            selection = "#fdfff11a";
          }
          {
            background = "#f92672";
            cursor = "#f92672";
            selection = "#f926721a";
          }
          {
            background = "#a6e22e";
            cursor = "#a6e22e";
            selection = "#a6e22e1a";
          }
          {
            background = "#fd971f";
            cursor = "#fd971f";
            selection = "#fd971f1a";
          }
          {
            background = "#e6db74";
            cursor = "#e6db74";
            selection = "#e6db741a";
          }
          {
            background = "#ae81ff";
            cursor = "#ae81ff";
            selection = "#ae81ff1a";
          }
          {
            background = "#66d9ef";
            cursor = "#66d9ef";
            selection = "#66d9ef1a";
          }
        ];
        predictive = "#919288";
        "scrollbar.thumb.active_background" = "#fdfff159";
        "scrollbar.thumb.background" = "#c0c1b526";
        "scrollbar.thumb.border" = "#c0c1b526";
        "scrollbar.thumb.hover_background" = "#fdfff126";
        "scrollbar.track.background" = "#272822";
        "scrollbar.track.border" = "#272822";
        # 对齐 IDEA TEXT_SEARCH_RESULT_ATTRIBUTES 背景 = #5F5F00
        # "search.match_background" = "#3d3e38";
        "search.match_background" = "#5f5f00";
        "status_bar.background" = "#20211c";
        "surface.background" = "#3b3c35";
        syntax = {
          attribute = {
            color = "#66d9ef";
            font_style = "italic";
          };
          boolean = {
            color = "#ae81ff";
          };

          # [2026-01-17] 参考IDEA的monokai 修改，让comment更清晰
          comment = {
            # color = "#6e7066";
            color = "#75715E";
            font_style = "italic";
          };

          "comment.doc" = {
            color = "#6e7066";
            font_style = "italic";
          };
          constant = {
            color = "#ae81ff";
          };
          constructor = {
            color = "#f92672";
          };
          emphasis = {
            font_style = "italic";
          };
          "emphasis.strong" = {
            font_weight = 700;
          };
          # Zed 只有单一 function 色位：取 IDEA 函数声明色 #a6e22e
          # function = { color = "#a6e22e"; };
          function = {
            color = "#a6e22e";
          };
          keyword = {
            color = "#f92672";
          };
          label = {
            color = "#a6e22e";
          };
          link_text = {
            # 对齐 IDEA：Markdown 链接文本改为浅蓝（原先红色留给 Markdown 结构符号）
            color = "#c7c7ff";
          };
          link_uri = {
            color = "#a6e22e";
          };
          number = {
            color = "#ae81ff";
          };
          operator = {
            color = "#f92672";
          };
          preproc = {
            color = "#ae81ff";
          };
          # [2026-01-17] 原目标是只改 YAML 的 key 颜色，但 Zed 目前无法在主题层面按语言区分 key。
          # 原因：
          # 1) 主题只认识 Tree-sitter 的 capture（如 property），对同名 capture 是全局生效的。
          # 2) YAML 的 key 当前 capture 只有 property（已通过 editor: copy highlight json 验证）。
          # 3) zed.dev/docs/languages/yaml 主要是 LSP/格式化/Schema，不提供更细粒度的 key 高亮配置入口。
          # 可行但更复杂的方案（未采用）：
          # - 自建/本地 language extension，提供 languages/yaml/highlights.scm。
          # - 在 highlights.scm 中把 YAML key 捕获为 @property.yaml_key。
          # - 主题里再配置 syntax."property.yaml_key" = { color = "#f92672"; } 以实现“只改 YAML”。
          # 结论：为保持配置简单与可维护性，最终选择全局修改所有语言的 key（property）。
          property = {
            color = "#f92672";
          };
          # 对齐 IDEA：标点多继承默认前景色（接近 #f8f8f2）
          # punctuation = { color = "#919288"; };
          # "punctuation.bracket" = { color = "#919288"; };
          # "punctuation.delimiter" = { color = "#919288"; };
          # "punctuation.list_marker" = { color = "#919288"; };
          # "punctuation.special" = { color = "#919288"; };
          punctuation = {
            # Markdown code fence / emphasis 等符号统一改红（全局标点会受影响）
            color = "#f92672";
          };
          "punctuation.bracket" = {
            color = "#f8f8f2";
          };
          "punctuation.delimiter" = {
            color = "#f8f8f2";
          };
          "punctuation.list_marker" = {
            # Markdown 无序/有序列表标记改红（全局 list marker 会受影响）
            color = "#f92672";
          };
          "punctuation.special" = {
            color = "#f8f8f2";
          };
          string = {
            color = "#e6db74";
          };
          # 对齐 IDEA VALID_STRING_ESCAPE = #ae81ff
          # "string.escape" = { color = "#fdfff1"; };
          "string.escape" = {
            color = "#ae81ff";
          };
          "string.regex" = {
            color = "#e6db74";
          };
          "string.special" = {
            color = "#fd971f";
          };
          "string.special.symbol" = {
            color = "#fd971f";
          };
          tag = {
            color = "#f92672";
          };

          # Markdown heading 改成红色
          # 注意在Zed里，整个heading是作为整体出现的（而非拆分为 # 和 title内容 两部分，所以渲染时，也只能作为整体渲染为红色）“标题整行是一个 title capture（# 和文字都在一起）”
          title = {
            color = "#f92672";
          };
          # 同上，只能作为整体进行渲染
          "text.literal" = {
            color = "#e6db74";
          };

          # 对齐 IDEA CLASS_REFERENCE / TYPE_REFERENCE = #a6e22e
          # type = { color = "#66d9ef"; };
          type = {
            color = "#a6e22e";
          };
          variable = {
            color = "#fdfff1";
          };
          "variable.special" = {
            color = "#ae81ff";
          };
        };
        "tab.active_background" = "#272822";
        "tab.inactive_background" = "#20211c";
        "tab_bar.background" = "#20211c";
        # 终端颜色对齐 IDEA Console 输出色
        # "terminal.ansi.black" = "#3b3c35";
        "terminal.ansi.black" = "#272822";
        # "terminal.ansi.blue" = "#fd971f";
        "terminal.ansi.blue" = "#c7c7ff";
        # "terminal.ansi.bright_black" = "#6e7066";
        "terminal.ansi.bright_black" = "#a7a7a7";
        # "terminal.ansi.bright_blue" = "#fd971f";
        "terminal.ansi.bright_blue" = "#c7c7ff";
        # IDEA Console CYAN 输出值为 #6b8b8（位数异常），先保留原值
        # "terminal.ansi.bright_cyan" = "#66d9ef";
        "terminal.ansi.bright_cyan" = "#66d9ef";
        # "terminal.ansi.bright_green" = "#a6e22e";
        "terminal.ansi.bright_green" = "#68e868";
        # "terminal.ansi.bright_magenta" = "#ae81ff";
        "terminal.ansi.bright_magenta" = "#ff2eff";
        # "terminal.ansi.bright_red" = "#f92672";
        "terminal.ansi.bright_red" = "#ff6767";
        # "terminal.ansi.bright_white" = "#fdfff1";
        "terminal.ansi.bright_white" = "#ffffff";
        # "terminal.ansi.bright_yellow" = "#e6db74";
        "terminal.ansi.bright_yellow" = "#754200";
        # IDEA Console CYAN 输出值为 #6b8b8（位数异常），先保留原值
        # "terminal.ansi.cyan" = "#66d9ef";
        "terminal.ansi.cyan" = "#66d9ef";
        # "terminal.ansi.green" = "#a6e22e";
        "terminal.ansi.green" = "#68e868";
        # "terminal.ansi.magenta" = "#ae81ff";
        "terminal.ansi.magenta" = "#ff2eff";
        # "terminal.ansi.red" = "#f92672";
        "terminal.ansi.red" = "#ff6767";
        # "terminal.ansi.white" = "#fdfff1";
        "terminal.ansi.white" = "#ffffff";
        # "terminal.ansi.yellow" = "#e6db74";
        "terminal.ansi.yellow" = "#754200";
        "terminal.background" = "#272822";
        text = "#fdfff1";
        "text.accent" = "#e6db74";
        "text.muted" = "#919288";
        "title_bar.background" = "#161713";
        "toolbar.background" = "#272822";
        "vim.insert.background" = "#a6e22e";
        "vim.mode.text" = "#272822";
        "vim.normal.background" = "#e6db74";
        "vim.visual.background" = "#fd971f";
        warning = "#fd971f";
        "warning.background" = "#20211c";
        "warning.border" = "#131310";
      };
    }
  ];
}
