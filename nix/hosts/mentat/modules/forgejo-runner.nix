{ pkgs, config, ... }:
let
  runnerDir = "/var/lib/forgejo-runner";
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
        container = {
          workdir_parent = "${runnerDir}/workspace";
          # Increase shared memory for containers (default 64MB is too small for Metro/Gradle)
          options = "--shm-size=2g";
        };
        host = {
          workdir_parent = "${runnerDir}/action-cache-dir";
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
        nixVersions.latest
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
        "nix:docker://localhost:5921/nix-runner"
      ];
    };
  };

  systemd.services.gitea-runner-nix = {
    environment = {
      XDG_CONFIG_HOME = runnerDir;
      XDG_CACHE_HOME = "${runnerDir}/.cache";
    };
    serviceConfig.PrivateTmp = false;
  };
  users.groups.gitea-runner = { };
  users.users.gitea-runner = {
    isSystemUser = true;
    group = "gitea-runner";
    extraGroups = [ "docker" ];
    home = runnerDir;
  };
}
