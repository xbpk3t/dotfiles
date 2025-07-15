{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Node.js 生态
    nodejs
    nodePackages.eslint
    nodePackages.pnpm
    tsx
    # wrangler  # 构建时间太长，暂时移除

    # Web 开发
    tailwindcss
    tailwindcss-language-server
  ];
}
