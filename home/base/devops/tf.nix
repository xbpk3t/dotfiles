{
  pkgs,
  lib,
  mylib,
  config,
  ...
}:
let
  cfg = config.modules.devops.tf;
  tools = mylib.infraTools { inherit pkgs; };
in
{
  options.modules.devops.tf = {
    enable = lib.mkEnableOption "Terraform/OpenTofu toolchain";

    opentofu.enable = lib.mkEnableOption "OpenTofu + terranix";

    terramate.enable = lib.mkEnableOption "Terramate";

    lint.enable = lib.mkEnableOption "Terraform lint/docs (tflint / terraform-docs)";

    ansible.enable = lib.mkEnableOption "Ansible / ansible-lint";
  };

  config = lib.mkMerge [
    {
      # 注意：保持无条件 definition（空列表也算），否则选项 default 会重新生效。
      # Terraform LSP 包，供 zed/helix 等 IDE 使用
      modules.langs.lsp.packages = lib.optionals cfg.enable [ pkgs.terraform-ls ];
    }
    (lib.mkIf cfg.enable {
      # 包清单见 lib/infra-tools.nix（与 devShells.infra 同源）；这里只决定
      # 哪些能力装进 home profile。
      home.packages =
        lib.optionals cfg.opentofu.enable tools.opentofu
        ++ lib.optionals cfg.terramate.enable tools.terramate
        ++ lib.optionals cfg.lint.enable tools.lint
        ++ lib.optionals cfg.ansible.enable (
          with pkgs;
          [
            # CICD
            ansible
            ansible-lint
          ]
        );
    })
  ];
}
