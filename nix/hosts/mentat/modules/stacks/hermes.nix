{ config, flake, ... }:
let
  my = config.services.my.hermes;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    matrixHermesToken = { };
    minimaxKey = { };
  };

  sops.templates."hermes.env" = {
    restartUnits = [ (quadlet.service containers.hermes) ];
    content = ''
      MATRIX_ACCESS_TOKEN=${config.sops.placeholder.matrixHermesToken}
      MINIMAX_API_KEY=${config.sops.placeholder.minimaxKey}
    '';
  };

  services.my.hermes = {
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
          volumes = [ "${my.stack.path}/data:/opt/data" ];
          environments = {
            HERMES_UID = toString my.stack.user.uid;
            HERMES_GID = toString my.stack.user.gid;
            MATRIX_HOMESERVER = "https://matrix.org";
            MATRIX_ALLOWED_USERS = "@keyruu:matrix.org";
            MATRIX_E2EE_MODE = "required";
          };
          environmentFiles = [ config.sops.templates."hermes.env".path ];
        };
      };
    };
  };
}
