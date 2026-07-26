{ config, ... }:
let
  port = 7384;
  domain = "cache.keyruu.de";
in
{
  sops.secrets.nixServeKey = { };

  networking = {
    hosts."127.0.0.1" = [ domain ];
    firewall.interfaces.${config.services.mesh.interface}.allowedTCPPorts = [ port ];
  };

  services.my.nix-serve = {
    inherit port domain;
    proxy = {
      enable = true;
      cert = {
        provided = false;
        host = domain;
      };
    };
  };

  # replaces nix-serve-ng, which core-dumped (SIGABRT in dumpPath) under
  # parallel NAR downloads, killing all in-flight streams
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.sops.secrets.nixServeKey.path ];
    settings.bind = "0.0.0.0:${toString port}";
  };
}
