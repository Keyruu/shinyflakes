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
    renovateDockerPassword = {
      owner = "renovate";
    };
  };

  nix.settings.trusted-users = [ "renovate" ];

  services.renovate = {
    enable = true;
    environment = {
      LOG_LEVEL = "debug";
    };
    credentials = {
      RENOVATE_TOKEN = config.sops.secrets.renovateToken.path;
      RENOVATE_GIT_PRIVATE_KEY = config.sops.secrets.renovateKey.path;
      RENOVATE_GITHUB_COM_TOKEN = config.sops.secrets.renovateGithubToken.path;
      DOCKER_HUB_PASSWORD = config.sops.secrets.renovateDockerPassword.path;
    };
    schedule = "hourly";
    settings = {
      endpoint = "https://git.keyruu.de";
      gitAuthor = "Renovate <renovate@keyruu.de>";
      platform = "forgejo";
      platformAutomerge = false;
      automergeStrategy = "rebase";
      extends = [ ":disableMonorepoGrouping" ];
      autodiscover = true;
      autodiscoverFilter = [ "lucas/*" ];

      hostRules = [
        # {
        #   hostType = "docker";
        #   matchHost = "docker.io";
        #   username = "keyruu";
        #   password = "\${DOCKER_HUB_PASSWORD}";
        # }
        # {
        #   hostType = "docker";
        #   matchHost = "ghcr.io";
        #   username = "Keyruu";
        #   password = "\${RENOVATE_GITHUB_COM_TOKEN}";
        # }
      ];

      allowedPostUpgradeCommands = [
        "^bash -c 'nix run \\.#update-hash -- .+'$"
        "^bash -c 'if \\[ -f flake\\.nix \\]; then nix-update --flake --version=skip default; fi'$"
      ];
      # nixpkgs bash (SSH_SOURCE_BASHRC) treats node's socketpair stdio as an
      # ssh session and sources /etc/bashrc -> /etc/profile, clobbering the
      # unit PATH in every exec child (nix-update: command not found).
      # NOSYSBASHRC makes /etc/bashrc return early.
      customEnvVariables.NOSYSBASHRC = "1";
      nix.enabled = true;
      pinDigests = true;
      packageRules = [
        {
          description = "refresh nix FOD hashes (npmDepsHash/cargoHash) after JS/Rust dep updates; repos must expose packages.default";
          matchManagers = [
            "npm"
            "cargo"
          ];
          postUpgradeTasks = {
            commands = [ "bash -c 'if [ -f flake.nix ]; then nix-update --flake --version=skip default; fi'" ];
            fileFilters = [ "**/*.nix" ];
            executionMode = "branch";
          };
        }
        {
          description = "single PR for all npm deps — one nix hash update per cycle";
          matchManagers = [ "npm" ];
          groupName = "npm dependencies";
        }
        {
          description = "npm/pnpm releases wait 7 days to match pnpm-workspace minimumReleaseAge gate";
          matchManagers = [ "npm" ];
          minimumReleaseAge = "7 days";
        }
        {
          description = "npm lockfile refresh bypasses release-age rules — require manual review";
          matchManagers = [ "npm" ];
          matchUpdateTypes = [ "lockFileMaintenance" ];
          automerge = false;
        }
      ];
      lockFileMaintenance = {
        enabled = true;
        automerge = true;
        automergeType = "branch";
        schedule = [ "after 4am and before 5am every day" ];
      };
      osvVulnerabilityAlerts = true;
      prConcurrentLimit = 0;
      branchConcurrentLimit = 0;
      prHourlyLimit = 0;

      # Recommended defaults from https://github.com/NuschtOS/nixos-modules/blob/db6f2a33500dadb81020b6e5d4281b4820d1b862/modules/renovate.nix
      cachePrivatePackages = true;
      configMigration = true;
      optimizeForDisabled = true;
      persistRepoData = true;
      repositoryCache = "enabled";
    };
    runtimePackages = with pkgs; [
      bash
      gnupg
      openssh
      nodejs
      pnpm
      yarn
      nix-update
      config.nix.package
    ];
  };
}
