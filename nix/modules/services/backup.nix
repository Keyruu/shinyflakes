{
  lib,
  config,
  options,
  ...
}:

let
  backupModules = options.services.restic.backups.type.nestedTypes.elemType.getSubModules;
in
{
  options.services.restic = {
    defaults = {
      repo = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      repoFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "04:00";
      };
    };

    backupsWithDefaults = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = backupModules ++ [
            (
              { name, ... }:
              {
                config = {
                  initialize = lib.mkDefault true;
                  repository = lib.mkDefault config.services.restic.defaults.repo;
                  repositoryFile = lib.mkDefault config.services.restic.defaults.repoFile;
                  passwordFile = lib.mkDefault config.sops.secrets.resticPassword.path;

                  pruneOpts = [
                    "--tag ${name}"
                    "--keep-daily 5"
                    "--keep-weekly 3"
                    "--keep-monthly 2"
                  ];

                  extraBackupArgs = [
                    "--host ${config.networking.hostName}"
                    "--tag ${name}"
                  ];

                  timerConfig = {
                    OnCalendar = lib.mkDefault config.services.restic.defaults.onCalendar;
                  };
                };
              }
            )
          ];
        }
      );
      default = { };
      description = "Define backups here. Inherits all Restic options + Global Defaults.";
    };
  };

  config =
    let
      backupNames = lib.attrNames config.services.restic.backupsWithDefaults;
    in
    {
      sops.secrets.resticPassword = { };
      services.restic.backups = config.services.restic.backupsWithDefaults;

      systemd.services = lib.listToAttrs (
        lib.imap0 (
          i: name:
          lib.nameValuePair "restic-backups-${name}" {
            after = lib.optional (i > 0) "restic-backups-${lib.elemAt backupNames (i - 1)}.service";
          }
        ) backupNames
      );
    };
}
