---
title: 删除nvim相关配置后的review
---

:::tip

直接用 helix 替代 nvim 了

helix和nvim是“尺有所长，寸有所短”，应该这段时间的使用，可以说二者竞争的都是Editor（而非IDE）这个生态位（这点需要格外注意）。

helix相较于nvim的优缺点真就是一体两面。helix的内存占用仅30MB，代价就是不支持plugins（helix本身就是all-in-one，所有plugins都是官方提供），而nvim的插件则完全开放，导致内存占用就高很多（200MB左右）。

**_之所以用 helix 替代 nvim，核心原因就在于此。原本寄希望于可以用 nvim 替代 IDE（但是多次尝试后无果，也认识到了二者压根不在一个生态位），那么 nvim 这个支持自定义plugins的优势，对我来说就没意义了，如果只作为 Terminal Editor 的话，我觉得 helix 更好用。_**

---

简单来说，helix是自上而下，而nvim则是自下而上。

前者有统一设计，一致性更好，资源开销低。后者则胜在生态开放、插件丰富。

但是一旦把这类工具的定位从IDE，改为Terminal Editor的话，那么helix就完胜nvim了，主打一个不折腾





:::

```yaml
- url: https://github.com/NotAShelf/nvf
  doc: https://notashelf.github.io/nvf/
  score: 5
  des: 【Nix的neovim配置】
  rel:
    - url: https://github.com/akinsho/toggleterm.nvim
      score: 5
      des: 【】
      record:
        - date: 2025-11-10
          des: Remove lazygit.nvim,

    # https://mynixos.com/nixpkgs/package/vimPlugins.auto-save-nvim
    - url: https://github.com/okuuva/auto-save.nvim/

    - url: https://github.com/ahmedkhalf/project.nvim
      score: 4

    - url: https://github.com/mistweaverco/kulala.nvim

    - url: https://github.com/jellydn/hurl.nvim/
    - url: https://github.com/mfussenegger/nvim-dap
    - url: https://github.com/loctvl842/monokai-pro.nvim

    - url: https://github.com/yetone/avante.nvim
    - url: https://github.com/dstein64/nvim-scrollview

    - url: https://github.com/folke/flash.nvim
    - url: https://github.com/kylechui/nvim-surround
    - url: https://github.com/folke/zen-mode.nvim
    - url: https://github.com/nvim-lualine/lualine.nvim
      score: 5
    - url: https://github.com/ThePrimeagen/harpoon
    - url: https://github.com/nvim-neo-tree/neo-tree.nvim
      score: 5

    - url: https://github.com/nvim-pack/nvim-spectre
    - url: https://github.com/nvim-telescope/telescope.nvim
      score: 5
    - url: https://github.com/ibhagwan/fzf-lua
  record:
    - date: 2025-07-12
      des: 1、用【nixvim】替换之前的neovim.nix。2、把【zensh】里的.zshrc整合到现在的shell.nix。3、把部分home/core.nix里的pkg迁移到modules/apps.nix里。4、移除掉了 fzf, eza, yazi, skim, direnv 这几个昨天放在nix的配置。5、最重要的，把modules里的pkg按照现在gh的结构重新拆分。
    - date: 2025-08-11
      des: 移除【vim-plug（比vundle好用）】

    - date: 2025-10-12
      des: |
        连续尝试了nvim和zed，拿以下这几条
        1、我很需要IDEA类似 scratches这种东西
        2、是否有类似 monokai 这种高亮theme
        3、文件树是否提示git状态？
        4、我需要类似 CMD+E 切换最近修改文件
        5、IDEA有极为丰富的DB driver支持。这个neovim应该没办法了吧，是不是这种场景下比较好的方案就是各种 web UI方案? 比如说 phpmysqladmin, phpRedisAdmin？还是说有更好的方案？
        6、是否支持项目级别批量查找、替换操作？包括正则查找、替换？
        7、是否支持自定义TODO filter?
        8、是否支持同时打开多个项目？以及项目之间通过快捷键切换？
        9、调试时能设置断点吗？是否有类似IDEA内置的这些操作？
        基于以上这几个需求

    # [Why I'm Dropping These Neovim Plugins (Less Is More) ](https://www.youtube.com/watch?v=8VeF2ROFAas)
    - date: 2025-11-10
      des: 之前已经移除插件【kulala】hurl, yaml_companion, zen_mode. After watching this youtube video, I immediately deleted below plugins, Avante.nvim, Harpoon, flash.nvim, lualine.

    - date: 2025-11-13
      des: 最终还是用回了goland，***“何必跟自己较劲呢？”***，为期近15天的尝试结束了，这次从【2025-10-30】开始，直到今天为止都在使用nvim。这次尝试起始于某次rebuild之后，goland直接无法打开了，所以转而去用nvim。从youtube看了各种视频，找到各种常用plugins，都安装上使用后，建立了自己对nvim的sense后，又删除了其实没啥用的。在。我的结论是：***在desktop端，goland确实更省心，使用体验更好，效率更高。但也不要非此即彼。即使用回了goland，我也不会直接删除nvf的相关配置。*** 因为能够在terminal实现跟，我用回goland，是不想跟自己较劲了，是因为自己太菜了，是我不会用nvim。
    - date: 2025-12-23
      des: 移除【todo-comments.nvim】

  topics:
    - topic: Nvim/nvf
      why:
        - 【生态位/边界】

        # ***[Which one should I use: programs.neovim, nixCats-nvim, nixvim or nvf? | DevCtrl](https://devctrl.blog/posts/which-one-should-i-use-programs-neovim-nix-cats-nvim-nixvim-or-nvf/)***
        - 【技术选型】为啥我选择使用nvf，而非 nixvim。也没有选择 LazyVim / LunarVim / AstroNvim / NvChad 之类的 nvim发行版？

        # lazy.nvim neovim插件管理器
```
