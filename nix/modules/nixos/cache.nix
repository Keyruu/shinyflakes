{ config, ... }:
{
  sops.secrets = {
    nixCacheAccessKey = { };
    nixCacheSecretKey = { };
  };

  nix.settings = {
    substituters = [
      "s3://nix-cache?scheme=https&endpoint=s3.keyruu.de&region=garage"
    ];
    trusted-public-keys = [
      "cache.keyruu.de:HJ0p1nhtvgqm5KIo07CRmfZW9lIA7x4SvUIdjaS+OdE="
    ];
  };

  systemd.services.nix-daemon.serviceConfig = {
    EnvironmentFile = config.sops.templates."nix-s3-env".path;
  };

  sops.templates."nix-s3-env".content = ''
    AWS_ACCESS_KEY_ID=${config.sops.placeholder.nixCacheAccessKey}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.nixCacheSecretKey}
  '';
}
