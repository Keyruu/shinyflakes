{pkgs, lib, config, ...}: {
  networking = {
    usePredictableInterfaceNames = true;
    nameservers = ["192.168.100.1"];
    defaultGateway = {
      address = "192.168.100.1";
      interface = "enu1u1";
    };

    interfaces.enu1u1 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.100.5";
          prefixLength = 24;
        }
      ];
    };
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.headscaleAuthKey.path;
    extraUpFlags = [
      "--login-server=https://headscale.peeraten.net"
      "--advertise-exit-node"
      "--advertise-routes=192.168.100.0/24"
      "--accept-dns=false"
      "--accept-routes=false"
    ];
  };

  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale" = {
      onState = ["routable"];
      script = /* bash */ ''
        #!${pkgs.runtimeShell}
        ${lib.getExe pkgs.ethtool} -K enu1u1 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };
}

