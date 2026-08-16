{
  den.aspects.mentat.nixos = {
    services.my.cockpit = {
      domain = "mentat.lab.keyruu.de";
      proxy.enable = true;
      dashboard.title = "Cockpit";
    };
  };
}
