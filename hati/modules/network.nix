{ lib, ... }: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };

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
