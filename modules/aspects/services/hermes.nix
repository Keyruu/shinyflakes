{ ... }:
{
  den.aspects.services.hermes = {
    nixos = { config, ... }: {
      sops.secrets = {
        matrixHermesToken = { };
        matrixHermesRecoveryKey = { };
        minimaxKey = { };
      };

      sops.templates."hermes.env" = {
        restartUnits = [ "hermes.service" ];
        content = ''
          MATRIX_ACCESS_TOKEN=${config.sops.placeholder.matrixHermesToken}
          MATRIX_RECOVERY_KEY=${config.sops.placeholder.matrixHermesRecoveryKey}
          MINIMAX_API_KEY=${config.sops.placeholder.minimaxKey}
        '';
      };

      services.my.hermes = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
        backup.enable = true;
        stack = {
          enable = true;
          directories = [ "data" ];
          user = {
            enable = true;
            uid = 2998;
            gid = 2998;
          };
          security = {
            enable = true;
            memoryLimit = "4g";
            pidsLimit = 1024;
          };

          containers.hermes = {
            # s6-overlay init must usermod the internal user to HERMES_UID and
            # chown /opt/data before dropping privileges — needs writable /etc
            # and these caps despite the OWASP drop-ALL default
            security.readOnlyRootFilesystem = false;
            containerConfig = {
              image = "docker.io/nousresearch/hermes-agent:v2026.7.7.2";
              exec = [
                "gateway"
                "run"
              ];
              addCapabilities = [
                "CHOWN"
                "DAC_OVERRIDE"
                "FOWNER"
                "SETUID"
                "SETGID"
              ];
              volumes = [ "/etc/stacks/hermes/data:/opt/data" ];
              environments = {
                HERMES_UID = "2998";
                HERMES_GID = "2998";
                MATRIX_HOMESERVER = "https://matrix.org";
                MATRIX_ALLOWED_USERS = "@keyruu:matrix.org";
                MATRIX_E2EE_MODE = "required";
              };
              environmentFiles = [ config.sops.templates."hermes.env".path ];
            };
          };
        };
      };
    };
  };
}
