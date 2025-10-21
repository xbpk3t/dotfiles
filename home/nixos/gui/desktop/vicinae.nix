{
  config,
  pkgs,
  ...
}: {
  services.vicinae = {
    enable = true;
    autoStart = true;
    settings = {
      faviconService = "google"; # twenty | google | none
      font = {
        normal = "JetBrainsMono Nerd Font";
        size = 12;
      };

      popToRootOnClose = true;

      rootSearch = {
        searchFiles = false;
      };

      theme.name = "vicinae-dark";

      window = {
        csd = true;
        opacity = 0.95;
        rounding = 16;
      };
    };
  };

  # 部署 vicinae 扩展源代码
  # 扩展源代码放在 ~/.local/share/vicinae-ext-src/ext
  home.file.".local/share/vicinae-ext-src/ext" = {
    source = ./ext;
    recursive = true;
  };

  # 使用 home.activation 在部署时构建并安装扩展
  # 扩展应该安装在 ~/.local/share/vicinae/extensions/ 而不是 ~/.config/vicinae/extensions/
  # 参考: home/nixos/gui/desktop/ext/VERIFICATION.md
  home.activation.buildVicinaExt = config.lib.dag.entryAfter ["writeBoundary"] ''
    EXT_SRC="$HOME/.local/share/vicinae-ext-src/my-tools"
    EXT_DST="$HOME/.local/share/vicinae/extensions/my-tools"

    if [ -d "$EXT_SRC" ]; then
      echo "Building vicinae exts..."
      cd "$EXT_SRC"

      # 安装依赖（如果需要）
      if [ ! -d "node_modules" ]; then
        ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile || true
      fi

      # 构建扩展
      ${pkgs.pnpm}/bin/pnpm build || echo "Warning: Failed to build vicinae extension"

      # 复制构建产物到扩展目录
      if [ -d "dist" ]; then
        mkdir -p "$EXT_DST"
        cp -r dist/* "$EXT_DST/"
        # 复制 package.json 和 assets
        cp package.json "$EXT_DST/" || true
        [ -d "assets" ] && cp -r assets "$EXT_DST/" || true
        echo "Vicinae exts installed to $EXT_DST"
      fi
    fi
  '';
}
