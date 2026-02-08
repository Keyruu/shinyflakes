{ config, pkgs, ... }:
{
  users.groups.kanidm = { };
  users.users.kanidm = {
    isSystemUser = true;
    group = "kanidm";
    extraGroups = [
      "headscale"
    ];
  };

  sops.secrets = {
    kanidmAdminPassword.owner = "kanidm";
    traccarClientSecret.owner = "kanidm";
  };

  security.acme = {
    certs."auth.peeraten.net" = {
      group = "kanidm";
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.kanidm = {
    enableServer = true;
    package = pkgs.kanidmWithSecretProvisioning_1_8;
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
      systems.oauth2 = {
        # headscale = {
        #   present = true;
        #   displayName = "headscale.peeraten.net";
        #   allowInsecureClientDisablePkce = true;
        #   basicSecretFile = config.sops.secrets.headscaleOidc.path;
        #   originUrl = "https://headscale.peeraten.net/oidc/callback";
        #   originLanding = "https://headscale.peeraten.net/";
        #   scopeMaps = {
        #     headscale_users = [
        #       "openid"
        #       "email"
        #       "profile"
        #     ];
        #   };
        # };
        traccar = {
          present = true;
          displayName = "traccar.peeraten.net";
          allowInsecureClientDisablePkce = true;
          basicSecretFile = config.sops.secrets.traccarClientSecret.path;
          originUrl = "https://traccar.peeraten.net/api/session/openid/callback";
          originLanding = "https://traccar.peeraten.net/";
          scopeMaps = {
            traccar_users = [
              "openid"
              "email"
              "profile"
            ];
          };
        };
      };
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

  services.caddy.virtualHostsWithDefaults."auth.peeraten.net".extraConfig = ''
    import cloudflare-only
    reverse_proxy https://${toString config.services.kanidm.serverSettings.bindaddress} {
      transport http {
        tls
        tls_server_name auth.peeraten.net
      }
    }
  '';
}
