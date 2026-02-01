{ config, pkgs, ... }:
{
  users = {
    groups.renovate.gid = 1005;
    users = {
      renovate = {
        isSystemUser = true;
        uid = 1005;
        group = "renovate";
      };
    };
  };

  sops.secrets = {
    renovateToken = {
      owner = "renovate";
    };
    renovateKey = {
      owner = "renovate";
    };
    renovateGithubToken = {
      owner = "renovate";
    };
  };

  services.renovate = {
    enable = true;
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets.renovateToken.path;
      RENOVATE_GIT_PRIVATE_KEY = config.sops.secrets.renovateKey.path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets.renovateGithubToken.path;
    };
    schedule = "hourly";
    settings = {
      endpoint = "https://git.keyruu.de";
      gitAuthor = "Renovate <renovate@keyruu.de>";
      platform = "forgejo";
      platformAutomerge = true;
      autodiscover = true;

      packageRules = [
        {
          matchUpdateTypes = [
            "minor"
            "patch"
          ];
          matchCurrentVersion = "!/^0/";
          automerge = true;
        }
      ];

      nix.enabled = true;
      lockFileMaintenance = {
        enabled = true;
        automerge = true;
        schedule = [ "* * * * *" ];
      };
      osvVulnerabilityAlerts = true;

      # Recommended defaults from https://github.com/NuschtOS/nixos-modules/blob/db6f2a33500dadb81020b6e5d4281b4820d1b862/modules/renovate.nix
      cachePrivatePackages = true;
      configMigration = true;
      optimizeForDisabled = true;
      persistRepoData = true;
      repositoryCache = "enabled";
    };
    runtimePackages = with pkgs; [
      gnupg
      openssh
      nodejs
      yarn
      config.nix.package
    ];
  };

}
