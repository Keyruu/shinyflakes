{
  config,
  pkgs,
  ...
}:
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

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    inherit port;
    openFirewall = false;
    bindAddress = "0.0.0.0";
    secretKeyFile = config.sops.secrets.nixServeKey.path;
  };
}
