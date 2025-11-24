{ config, inputs, ... }:
let
  stackPath = "/etc/stacks/niks3";
in
{
  imports = [ inputs.niks3.nixosModules.default ];

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  users.groups.niks3 = { };
  sops.secrets = {
    nixCacheAccessKey = {
      group = "niks3";
      mode = "0440";
    };
    nixCacheSecretKey = {
      group = "niks3";
      mode = "0440";
    };
    niks3ApiToken = {
      group = "niks3";
      mode = "0440";
    };
    niks3SigningKey = {
      group = "niks3";
      mode = "0440";
    };
  };

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:5751";

    s3 = {
      endpoint = "s3.keyruu.de";
      bucket = "nix-cache";
      useSSL = true;
      accessKeyFile = config.sops.secrets.nixCacheAccessKey.path;
      secretKeyFile = config.sops.secrets.nixCacheSecretKey.path;
    };

    apiTokenFile = config.sops.secrets.niks3ApiToken.path;
    signKeyFiles = [ config.sops.secrets.niks3SigningKey.path ];

    cacheUrl = "https://cache.keyruu.de";

    gc = {
      enable = true;
      olderThan = "720h"; # 30 days
      failedUploadsOlderThan = "6h";
      schedule = "daily";
      randomizedDelaySec = 1800;
    };
  };

  services.nginx.virtualHosts."cache.keyruu.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5751";
      proxyWebsockets = true;
    };
  };
}
