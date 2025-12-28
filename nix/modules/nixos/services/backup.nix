{
  lib,
  config,
  options,
  ...
}:
let
  cfg = config.services.restic;
  backupsType = options.services.restic.backups.type;
  backupType = backupsType.elemType;
in
{
  options = {
    services.restic.backupsWithDefaults = lib.mkOption {
      type = backupType;
      description = ''
        Backups with our own defaults applied.
      '';
      default = { };
    };

    services.restic.backupDefault = lib.mkOption {
      type = backupType;
      description = ''
        Define default options for every backup.
      '';
      default = { };
    };
  };

  config = {
    services.restic.backups = lib.mapAttrs (
      _key: backup: lib.recursiveUpdate cfg.backupDefault backup
    ) cfg.backupsWithDefaults;
  };
}
