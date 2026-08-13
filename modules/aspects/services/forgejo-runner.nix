{ ... }:
{
  den.aspects.services.forgejo-runner = {
    nixos =
      { pkgs, config, ... }:
      let
        runnerDir = "/var/lib/gitea-runner";
      in
      {
        sops.secrets = {
          forgejoRunnerToken = {
            owner = "gitea-runner";
            group = "gitea-runner";
          };
        };

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.nix = {
            settings = {
              cache = {
                enabled = true;
              };
            };
            hostPackages = with pkgs; [
              bash
              coreutils
              curl
              jq
              direnv
              gawk
              git-lfs
              gitFull
              gnused
              config.nix.package
              nixos-rebuild-ng
              just
              nodejs
              openssh
              wget
              trivy
            ];
            enable = true;
            name = config.networking.hostName;
            url = "https://git.keyruu.de";
            tokenFile = config.sops.secrets.forgejoRunnerToken.path;
            labels = [
              "nixos-${pkgs.stdenv.hostPlatform.system}:host"
            ];
          };
        };

        users.groups.gitea-runner = { };
        users.users.gitea-runner = {
          isSystemUser = true;
          group = "gitea-runner";
          home = runnerDir;
        };
      };
  };
}
