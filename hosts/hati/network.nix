{lib, ...}: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443 3010 3020];
    };

    nameservers = ["192.168.100.1" "1.1.1.1"];
    defaultGateway = {
      address = "192.168.100.1";
      interface = "eth0";
    };

    useDHCP = lib.mkDefault true;
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.100.18";
          prefixLength = 24;
        }
      ];
    };
  };
}
