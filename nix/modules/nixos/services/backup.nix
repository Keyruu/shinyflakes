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
    defaultRepo = lib.mkOption { type = lib.types.str; };

    backupsWithDefaults = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = backupModules ++ [
            (
              { name, ... }:
              {
                config = {
                  initialize = lib.mkDefault true;
                  repository = lib.mkDefault config.services.restic.defaultRepo;
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
              }
            )
          ];
        }
      );
      default = { };
      description = "Define backups here. Inherits all Restic options + Global Defaults.";
    };
  };

  config = {
    services.restic.backups = config.services.restic.backupsWithDefaults;
  };
}
