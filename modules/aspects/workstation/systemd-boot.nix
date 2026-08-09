{
  den.aspects.systemd-boot = {
    nixos = { ... }: {
      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            configurationLimit = 10;
          };
          efi.canTouchEfiVariables = true;
        };
      };
    };
  };
}