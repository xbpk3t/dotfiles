{pkgs, ...}: {
  home.packages = with pkgs; [
    # Node.js 生态
    nodejs
    nodePackages.eslint
    pnpm
    nodePackages.serve # https://github.com/vercel/serve 用来preview本地打包好的dist文件（vite可以直接vite preview）

    # [2026-01-21] rebuild error, hash mismatch, so comment it
    # tsx

    typescript
    # error: 'ts-node' was removed because it is unmaintained, and since NodeJS 22.6.0+, experimental TypeScript support is built-in to NodeJS.
    # nodePackages.ts-node
    nodePackages.yaml-language-server

    # Web 开发
    # tailwindcss
    # tailwindcss-language-server
    npm-check # https://github.com/dylang/npm-check 可以认为 npm-check = depcheck + npm-check-updates. 可以用来检查并自动更新dependency，也支持检查unused依赖项. Check for outdated, incorrect, and unused dependencies in package.json.
    npm-check-updates # https://github.com/raineorshine/npm-check-updates 顾名思义，相当于 `npm-check -u`，用来检查pkg版本是否有新版本. 支持brew安装。`ncu -u`

    # https://mynixos.com/nixpkgs/package/stylelint
    stylelint
  ];

  # https://mynixos.com/home-manager/options/programs.bun
  # [2026-01-19] 安装 OMO 需要先安装bun
  programs.bun = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      smol = true;
      telemetry = false;
      test = {
        coverage = true;
        coverageThreshold = 0.9;
      };
      install.lockfile = {
        # Whether to generate a non-Bun lockfile alongside bun.lock. (A bun.lock will always be created.) Currently "yarn" is the only supported value.
        print = "yarn";
      };
    };
  };
}
