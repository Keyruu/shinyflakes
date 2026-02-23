{ config, ... }:
let
  gitHost = "git.keyruu.de";
in
{
  sops = {
    secrets.forgejoRepoToken = { };
    templates."forgejoCreds".content =
      "https://<USERNAME>:${config.sops.placeholder.forgejoRepoToken}@${gitHost}";
  };

  programs.git = {
    enable = true;

    userName = "Lucas";
    userEmail = "keyruu@web.de";

    extraConfig = {
      pull.rebase = true;

      credential."https://git.keyruu.de" = {
        helper = "store --file ${config.sops.templates."forgejoCreds".path}";
      };
    };
  };
}
