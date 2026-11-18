{
  lib,
  mylib,
  ...
}:
{
  imports = [
    (mylib.relativeToRoot "home/base/devops/herdr-core.nix")
  ];

  modules.devops.herdr-core = {
    enable = true;
    settings.restore_screen = true;
  };

  # 厂商 PA 的 SSH 通常是非交互、窄 PATH；给 herdr-core 一个稳定入口。
  home.activation.linkHc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$HOME/.nix-profile/bin/hc" "$HOME/.local/bin/hc"
        if [ -x "$HOME/.nix-profile/bin/herdr-core" ]; then
          ln -sfn "$HOME/.nix-profile/bin/herdr-core" "$HOME/.local/bin/herdr-core"
        fi
        if [ -w /usr/local/bin ]; then
          ln -sfn "$HOME/.local/bin/hc" /usr/local/bin/hc
          if [ -x "$HOME/.local/bin/herdr-core" ]; then
            ln -sfn "$HOME/.local/bin/herdr-core" /usr/local/bin/herdr-core
          fi
        fi
        for f in "$HOME/.profile" "$HOME/.bashrc"; do
          touch "$f"
          grep -q 'hm-lightvela PATH' "$f" || cat >>"$f" <<'EOF'

    # >>> hm-lightvela PATH >>>
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
    # <<< hm-lightvela PATH <<<
    EOF
        done
  '';
}
