{ config, ... }:
let
  gitHost = "git.keyruu.de";
in
{
  sops = {
    secrets.forgejoRepoToken = { };
    templates."forgejoCreds".content =
      "https://x-access-token:${config.sops.placeholder.forgejoRepoToken}@${gitHost}";
  };

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Lucas";
        email = "keyruu@web.de";
      };
      pull.rebase = true;

      credential."https://git.keyruu.de" = {
        helper = "store --file ${config.sops.templates."forgejoCreds".path}";
      };
    };
  };
}
