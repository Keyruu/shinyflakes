{
  den.aspects.mentat.nixos = {
    services.my.cockpit = {
      title = "Cockpit";
      domain = "mentat.lab.keyruu.de";
      proxy.enable = true;
    };
  };
}
