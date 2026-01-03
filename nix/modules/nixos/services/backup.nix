{
  lib,
  config,
  options,
  ...
}:
let
  cfg = config.services.restic;
  backupType = options.services.restic.backups.type.nestedTypes.elemType;
in
{
  options.services.restic = {
    backupDefault = lib.mkOption {
      type = backupType;
      default = { };
      description = "Default backup configuration applied to all backups";
    };

    backupsWithDefaults = lib.mkOption {
      type = with lib.types; attrsOf backupType;
      default = { };
      description = ''
        Backups with our own defaults applied.
        Automatically adds: hostname and backup name tags, --host flag, retention-based pruning.
      '';
    };
  };

  config = {
    sops.secrets.resticPassword = { };
    services.restic.backups = lib.mapAttrs (
      name: backup:
      with lib;
      recursiveUpdate (recursiveUpdate {
        initialize = true;
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
          OnCalendar = "04:00";
          RandomizedDelaySec = "1h";
        };
        passwordFile = config.sops.secrets.resticPassword;
      } cfg.backupDefault) backup
    ) cfg.backupsWithDefaults;
  };
}
