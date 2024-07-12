{lib, ...}: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443 3010 3020];
    };

    nameservers = ["192.168.187.10" "1.1.1.1"];

    useDHCP = lib.mkDefault true;
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.187.18";
          prefixLength = 24;
        }
      ];
    };
  };
}
