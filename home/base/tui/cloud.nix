{pkgs, ...}: {
  # https://developer.hashicorp.com/terraform/cli/config/config-file
  #  home.file.".terraformrc".text = ''
  #    plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
  #    disable_checkpoint = true
  #  '';

  home.packages = with pkgs; [
    # infrastructure as code
    # pulumi
    # pulumictl
    # tf2pulumi
    # crd2pulumi
    # pulumiPackages.pulumi-random
    # pulumiPackages.pulumi-command
    # pulumiPackages.pulumi-aws-native

    # pulumiPackages.pulumi-language-go
    # pulumiPackages.pulumi-language-python
    # pulumiPackages.pulumi-language-nodejs

    # aws
    # awscli2
    # ssm-session-manager-plugin # Amazon SSM Session Manager Plugin
    # aws-iam-authenticator
    # eksctl

    # aliyun
    # aliyun-cli
    # digitalocean
    # doctl
    # google cloud
    #    (google-cloud-sdk.withExtraComponents (
    #      with google-cloud-sdk.components; [
    #        gke-gcloud-auth-plugin
    #      ]
    #    ))

    # cloud tools that nix do not have cache for.
    #    terraform
    #    terraformer # generate terraform configs from existing cloud resources
    #    packer # machine image builder
  ];
}
