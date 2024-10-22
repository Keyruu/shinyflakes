{pkgs, ...}: {
  services.printing = {
    enable = true;
    drivers = [pkgs.brlaser];
    listenAddresses = ["*:631"];
    allowFrom = ["all"];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_DCP-1510";
        location = "Home";
        deviceUri = "usb://Brother/DCP-1510%20series?serial=E72143M6N601788";
        model = "drv:///brlaser.drv/br1510.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "Brother_DCP-1510";
  };

  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    openFirewall = true;
    extraConfig = ''
      load printers = yes
      printing = cups
      printcap name = cups
      [printers]
      comment = All Printers
      path = /var/spool/samba
      public = yes
      browseable = yes
      # to allow user 'guest account' to print.
      guest ok = yes
      writable = no
      printable = yes
      create mode = 0700
    '';
  };
  systemd.tmpfiles.rules = [
    "d /var/spool/samba 1777 root root -"
  ];
}
