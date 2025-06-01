{ config, pkgs, ... }:
{
  users.groups.kanidm = { };
  users.users.kanidm = {
    isSystemUser = true;
    group = "kanidm";
    extraGroups = [
      "headscale"
      "nginx"
    ];
  };

  security.acme = {
    certs."auth.peeraten.net" = {
      group = "nginx";
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidm.withSecretProvisioning;
    serverSettings = {
      origin = "https://auth.peeraten.net";
      domain = "auth.peeraten.net";
      bindaddress = "127.0.0.1:8010";
      tls_chain = "${config.security.acme.certs."auth.peeraten.net".directory}/fullchain.pem";
      tls_key = "${config.security.acme.certs."auth.peeraten.net".directory}/key.pem";
    };
    provision = {
      enable = true;
      autoRemove = true;
      adminPasswordFile = config.sops.secrets.kanidmAdminPassword.path;
      idmAdminPasswordFile = config.sops.secrets.kanidmAdminPassword.path;
      persons = {
        lucas = {
          displayName = "Lucas";
          groups = [
            "headscale_users"
            "traccar_users"
          ];
          mailAddresses = [
            "lucas@keyruu.de"
          ];
        };
        nadine = {
          displayName = "Nadine";
          groups = [
            "headscale_users"
            "traccar_users"
          ];
          mailAddresses = [
            "nadine.october664@slmail.me"
          ];
        };
      };
      groups = {
        headscale_users = { };
        traccar_users = { };
      };
      # systems.oauth2 = {
      #   headscale = {
      #     displayName = "Headscale";
      #     allowInsecureClientDisablePkce = true;
      #     basicSecretFile = config.sops.secrets.headscaleOidc.path;
      #     originUrl = "https://headscale.peeraten.net/";
      #     originLanding = "https://headscale.peeraten.net/";
      #     scopeMaps = {
      #       headscale_users = [
      #         "openid"
      #         "email"
      #         "profile"
      #       ];
      #     };
      #   };
      # };
    };
  };

  systemd.services.kanidm.serviceConfig.BindReadOnlyPaths = [
    "/nix/store"
    # For healthcheck notifications
    "/run/systemd/notify"
    "-/etc/resolv.conf"
    "-/etc/nsswitch.conf"
    "-/etc/hosts"
    "-/etc/localtime"
    config.services.kanidm.serverSettings.tls_chain
    config.services.kanidm.serverSettings.tls_key
    "/run/secrets"
  ];

  services.nginx.virtualHosts."auth.peeraten.net" = {
    useACMEHost = "auth.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "https://${toString config.services.kanidm.serverSettings.bindaddress}";
      proxyWebsockets = true;
    };
  };
}
