{ ... }:
{
  den.aspects.workstation.sunshine = {
    nixos = { lib, ... }: {
      services.sunshine = {
        enable = true;
        capSysAdmin = true;
        autoStart = false;
        openFirewall = true;
      };

      services.avahi = {
        publish.enable = lib.mkForce null;
        publish.userServices = lib.mkForce null;
        settings.publish = {
          disable-publishing = false;
          disable-user-service-publishing = false;
          publish-addresses = true;
        };
      };
    };
  };
}
