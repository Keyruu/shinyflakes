{ ... }:
{
  den.aspects.tools.git = {
    homeManager =
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
            pull.rebase = true;

            credential."https://git.keyruu.de" = {
              helper = "store --file ${config.sops.templates."forgejoCreds".path}";
            };

            url."git@github.com:".insteadOf = "https://github.com/";

            # Git uses last matching identity; include must precede includeIf.
            include.path = "personal.inc";
            includeIf."gitdir:~/git/dash0/".path = "dash0.inc";
          };
        };

        xdg.configFile."git/personal.inc".text = ''
          [user]
              name = Lucas
              email = keyruu@web.de
        '';

        xdg.configFile."git/dash0.inc".text = ''
          [user]
              name = Lucas Rott
              email = lucas.rott@dash0.com
              signingkey = ~/.ssh/dash0_ed25519.pub
          [commit]
              gpgsign = true
          [gpg]
              format = ssh
          [gpg "ssh"]
              allowedSignersFile = ~/.ssh/allowed_signers
        '';
      };
  };
}
