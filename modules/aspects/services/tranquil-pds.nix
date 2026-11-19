{ ... }:
{
  den.aspects.services.tranquil-pds = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.tranquil-pds;
      in
      {
        sops.secrets = {
          resendApiKey = { };
          tranquilPdsJwtSecret = { };
          tranquilPdsDpopSecret = { };
          tranquilPdsMasterKey = { };
        };

        sops.templates."tranquil-pds.env" = {
          owner = "tranquil-pds";
          restartUnits = [ "tranquil-pds.service" ];
          content = ''
            JWT_SECRET=${config.sops.placeholder.tranquilPdsJwtSecret}
            DPOP_SECRET=${config.sops.placeholder.tranquilPdsDpopSecret}
            MASTER_KEY=${config.sops.placeholder.tranquilPdsMasterKey}
            MAIL_SMARTHOST_USERNAME=resend
            MAIL_SMARTHOST_PASSWORD=${config.sops.placeholder.resendApiKey}
          '';
        };

        services.my.tranquil-pds = {
          port = 2583;
          domain = "pds.keyruu.de";
          title = "PDS";
          description = "AT Protocol Personal Data Server";
          dashboard = {
            groups = [ "admin" ];
            icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bluesky.svg";
          };
          monitor.healthPath = "/xrpc/_health";
          backup = {
            enable = true;
            paths = [ "/var/lib/tranquil-pds" ];
            systemd.unit = "tranquil-pds.service";
          };
        };

        services.tranquil-pds = {
          enable = true;
          environmentFiles = [ config.sops.templates."tranquil-pds.env".path ];

          settings = {
            server = {
              inherit (my) port;
              hostname = my.domain;
              host = "127.0.0.1";
              # Handles live on the bare domain, not on pds.keyruu.de.
              user_handle_domains = [ "keyruu.de" ];
              # prime is a 40 GB VPS; the 10 GiB default could fill the disk.
              max_blob_size = 1073741824;
            };

            storage.repo_backend = "tranquil-store";

            # 0.8.0 still demands the key even though the embedded backend
            # never opens a postgres pool (see tranquil-startup/app_state.rs).
            database.url = "postgresql:///unused";

            email = {
              from_address = "pds@lab.keyruu.de";
              from_name = "keyruu.de PDS";
              # username/password go through the env file: config validation
              # rejects a half-set credential pair and only sees the file.
              smarthost = {
                host = "smtp.resend.com";
                port = 587;
              };
            };
          };
        };

        # No WAF in front: the OWASP CRS rules false-positive on xrpc JSON
        # bodies and break federation. DNS-only (no CF proxy) for the same
        # reason — the edge caps uploads and cuts firehose subscriptions.
        services.caddy.virtualHosts."${my.domain}".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString my.port}
        '';
      };
  };
}
