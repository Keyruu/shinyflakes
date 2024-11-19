{pkgs, lib, ...}: {
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

