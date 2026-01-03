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
    hostDefault = lib.mkOption {
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
      let
        globalDefaults = {
          initialize = lib.mkDefault true;
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
          timerConfig = lib.mkDefault {
            OnCalendar = "04:00";
            RandomizedDelaySec = "1h";
          };
        };

        defaults = lib.mkMerge [
          globalDefaults
          (lib.mapAttrs (_: lib.mkDefault) cfg.hostDefault)
        ];
      in
      lib.mkMerge [
        defaults
        backup
      ]
    ) cfg.backupsWithDefaults;
  };
}
