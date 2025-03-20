{config, ...}: let
  wudPath = "/etc/stacks/wud/store";
in {
  systemd.tmpfiles.rules = [
    "d ${wudPath} 0755 root root"
  ];

  sops.templates."wud.env".content = /* env */ ''
    WUD_TRIGGER_SMTP_RESEND_HOST=smtp.resend.com
    WUD_TRIGGER_SMTP_RESEND_PORT=587
    WUD_TRIGGER_SMTP_RESEND_FROM=wud@lab.keyruu.de
    WUD_TRIGGER_SMTP_RESEND_TO=me@keyruu.de
    WUD_TRIGGER_SMTP_RESEND_USER=resend
    WUD_TRIGGER_SMTP_RESEND_PASS=${config.sops.placeholder.resendApiKey}
  '';

  virtualisation.quadlet.containers.whatsupdocker = {
    containerConfig = {
      image = "ghcr.io/getwud/wud:8.0.1";
      environments = {
        TZ = "Europe/Berlin";
      };
      environmentFiles = [
        config.sops.templates."wud.env".path
      ];
      publishPorts = [
        "127.0.0.1:4833:3000"
      ];
      volumes = [
        "${wudPath}:/store"
        "/run/podman/podman.sock:/var/run/docker.sock"
      ];
      labels = [
        "wud.tag.include=^\d+\.\d+\.\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."wud.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:4833";
      proxyWebsockets = true;
    };
  };
}
