{ ... }:
{
  den.aspects.workstation.sunshine = {
    nixos = { ... }: {
      services.sunshine = {
        enable = true;
        capSysAdmin = true;
        autoStart = false;
        openFirewall = true;
      };
    };
  };
}
