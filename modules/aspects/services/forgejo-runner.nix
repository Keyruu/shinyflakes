{ ... }:
{
  den.aspects.services.forgejo-runner = {
    nixos =
      { pkgs, config, ... }:
      {
        sops.secrets.forgejoRunnerToken = { };

        services.forgejo-runner = {
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
            url = "https://git.keyruu.de";
            settings.server.connections.default.uuid = "500c43fe-394f-4b10-aac2-6f6b1595e4d2";
            secrets.server.connections.default.token_url = config.sops.secrets.forgejoRunnerToken.path;
            labels = [
              "nixos-${pkgs.stdenv.hostPlatform.system}:host"
            ];
          };
        };

      };
  };
}
