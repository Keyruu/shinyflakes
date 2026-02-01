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
        direnv
        docker
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

  # systemd.services.gitea-runner-nix = {
  #   environment = {
  #     XDG_CONFIG_HOME = runnerDir;
  #     XDG_CACHE_HOME = "${runnerDir}/.cache";
  #   };
  #   serviceConfig.PrivateTmp = false;
  # };
  users.groups.gitea-runner = { };
  users.users.gitea-runner = {
    isSystemUser = true;
    group = "gitea-runner";
    extraGroups = [ "podman" ];
    home = runnerDir;
  };
  nix.settings.trusted-users = [ "gitea-runner" ];
}
