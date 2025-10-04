{pkgs, ...}: {
  home.packages = with pkgs; [
    # Python
    python313

    # Rust
    rustup

    # 其他语言
    # php
    # elixir
    # android-tools

    lua

    # haskell
    # cabal-install

    # Node.js 生态
    nodejs
    nodePackages.eslint
    pnpm
    nodePackages.serve # https://github.com/vercel/serve 用来preview本地打包好的dist文件（vite可以直接vite preview）
    tsx

    typescript #
    nodePackages.ts-node

    # Web 开发
    # tailwindcss
    # tailwindcss-language-server
    npm-check # https://github.com/dylang/npm-check 可以认为 npm-check = depcheck + npm-check-updates. 可以用来检查并自动更新dependency，也支持检查unused依赖项. Check for outdated, incorrect, and unused dependencies in package.json.
    npm-check-updates # https://github.com/raineorshine/npm-check-updates 顾名思义，相当于 `npm-check -u`，用来检查pkg版本是否有新版本. 支持brew安装。`ncu -u`
  ];
}
