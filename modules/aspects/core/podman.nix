{ pkgs, ... }:
{
  den.aspects.podman = {
    nixos = { ... }: {
      environment.systemPackages = [
        pkgs.docker-compose
      ];

      # Must be the literal interface name: the nftables backend puts this straight
      # into an `iifname { ... }` set, where the iptables `+` wildcard never matches.
      networking.firewall.trustedInterfaces = [ "podman0" ];

      virtualisation.podman = {
        enable = true;
        autoPrune = {
          enable = true;
          flags = [ "--all" ];
          dates = "daily";
        };
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings = {
          # Required for container networking to be able to use names.
          dns_enabled = true;
        };
      };
    };
  };
}