{ config, pkgs, ... }:
let
  cfg = config.services.headscale;
  settingsFormat = pkgs.formats.yaml { };
  configFile = settingsFormat.generate "headscale.yaml" cfg.settings;

  stackPath = "/etc/stacks/headplane";
in
{
  sops.secrets = {
    headplaneCookieSecret = { };
    headplaneEnv = { };
    headscaleAuthKey = { };
    headscaleOidc = {
      group = "headscale";
      mode = "0440";
    };
  };

  sops.templates."headplane.yaml" = {
    restartUnits = [ "headplane.service" ];
    content = # yaml
      ''
        server:
          host: "0.0.0.0"
          port: 3000
          cookie_secret: "${config.sops.placeholder.headplaneCookieSecret}"
          cookie_secure: true

        headscale:
          url: "https://headscale.peeraten.net"
          config_path: "/etc/headscale/config.yaml"
          config_strict: true
        integration:
          agent:
            enabled: true
            pre_authkey: "${config.sops.placeholder.headscaleAuthKey}"
            host_name: "headplane-agent"
            cache_ttl: 60
            cache_path: /var/lib/headplane/agent_cache.json
            work_dir: "/var/lib/headplane/agent"
      '';
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  virtualisation.quadlet.containers.headplane = {
    containerConfig = {
      image = "ghcr.io/tale/headplane:0.6.1";
      publishPorts = [ "127.0.0.1:3000:3000" ];
      volumes = [
        "${configFile}:/etc/headscale/config.yaml:ro"
        "${config.sops.templates."headplane.yaml".path}:/etc/headplane/config.yaml:ro"
        "${stackPath}/data:/var/lib/headplane"
      ];
      environments = {
        HEADSCALE_URL = "https://headscale.peeraten.net";
      };
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      X-RestartTrigger = [
        "${configFile}"
        "${config.sops.templates."headplane.yaml".path}"
      ];
    };
  };

  services = {
    headscale = {
      enable = true;
      port = 8085;
      settings = {
        server_url = "https://headscale.peeraten.net";
        metrics_listen_addr = "0.0.0.0:8095";
        tls_cert_path = null;
        tls_key_path = null;
        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
        };
        database = {
          type = "sqlite3";
          sqlite.path = "/var/lib/headscale/db.sqlite";
        };
        dns = {
          override_local_dns = false;
          base_domain = "hafen.peeraten.net";
          magic_dns = true;
          # nameservers.split = {
          #   "lab.keyruu.de" = [
          #     "100.67.0.2"
          #   ];
          #   "home.zimtix.de" = [
          #     "100.67.0.2"
          #   ];
          #   "port.peeraten.net" = [
          #     "100.67.0.2"
          #   ];
          # };
        };
        oidc = {
          only_start_if_oidc_is_available = true;
          issuer = "https://auth.peeraten.net/oauth2/openid/headscale";
          client_id = "headscale";
          client_secret_path = config.sops.secrets.headscaleOidc.path;
          scope = [
            "openid"
            "profile"
            "email"
          ];
          pkce = {
            enabled = true;
          };
        };
      };
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      authKeyFile = config.sops.secrets.headscaleAuthKey.path;
      extraUpFlags = [
        "--login-server=http://127.0.0.1:8085"
        "--accept-routes=true"
      ];
    };

    caddy.virtualHostsWithDefaults."headscale.peeraten.net".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString config.services.headscale.port}
      reverse_proxy /admin* http://127.0.0.1:3000
    '';
  };
}
