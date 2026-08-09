{ ... }:
{
  den.aspects.backup.nixos = { lib, config, options, ... }: let
    backupModules = options.services.restic.backups.type.nestedTypes.elemType.getSubModules;
  in {
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
        hour = lib.mkOption {
          type = lib.types.ints.between 0 23;
          default = 4;
          description = "Hour of day (0-23) when backups start.";
        };
        spacingSec = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 30;
          description = "Seconds between consecutive backups. Each backup's timer is offset by index * spacingSec from `hour`. 0 disables spacing.";
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
                      OnCalendar = lib.mkDefault "*-*-* ${toString config.services.restic.defaults.hour}:00:00";
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
        spacingSec = config.services.restic.defaults.spacingSec;
        baseSec = config.services.restic.defaults.hour * 3600;

        offsetOnCalendar = i:
          let
            totalSec = baseSec + i * spacingSec;
            wrapped = totalSec - (totalSec / 86400) * 86400;
          in
          "*-*-* ${toString (wrapped / 3600)}:${toString (lib.mod (wrapped / 60) 60)}:${toString (lib.mod wrapped 60)}";

        onCalendarOverrides = lib.listToAttrs (
          lib.imap0 (i: name: lib.nameValuePair name {
            timerConfig.OnCalendar = lib.mkForce (offsetOnCalendar i);
          }) backupNames
        );
      in
      {
        sops.secrets.resticPassword = { };
        services.restic.backups = lib.mkMerge [
          config.services.restic.backupsWithDefaults
          # Per-backup OnCalendar override: each backup fires at onCalendar + index*spacingSec.
          onCalendarOverrides
        ];

        systemd.services = lib.listToAttrs (
          lib.imap0 (
            i: name:
            lib.nameValuePair "restic-backups-${name}" {
              after = lib.optional (i > 0) "restic-backups-${lib.elemAt backupNames (i - 1)}.service";
            }
          ) backupNames
        );
      };
  };
}