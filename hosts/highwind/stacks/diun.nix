{ config, ... }:
let
  diunPath = "/etc/stacks/diun/data";
in
{
  systemd.tmpfiles.rules = [
    "d ${diunPath} 0755 root root"
  ];

  sops.templates."diun.yml".content = # yaml
    ''
      watch:
        workers: 20
        schedule: "0 */6 * * *"
        firstCheckNotif: true
        runOnStartup: true

      notif:
        mail:
          host: smtp.resend.com
          port: 587
          username: resend
          password: ${config.sops.placeholder.resendApiKey}
          from: diun@lab.keyruu.de
          to:
            - me@keyruu.de

      providers:
        docker:
          watchByDefault: true
          watchStopped: true
    '';

  virtualisation.quadlet.containers.diun = {
    containerConfig = {
      image = "ghcr.io/crazy-max/diun:4.29.0";
      exec = "serve";
      environments = {
        TZ = "Europe/Berlin";
        DIUN_PROVIDERS_DOCKER = "true";
      };
      volumes = [
        "${diunPath}:/data"
        "${config.sops.templates."diun.yml".path}:/diun.yml:ro"
        "/run/podman/podman.sock:/var/run/docker.sock"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
