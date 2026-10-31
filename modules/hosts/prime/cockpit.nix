{
  den.aspects.prime.nixos = {
    services.my.cockpit = {
      domain = "prime.keyruu.de";
      origins = [
        "http://10.67.0.1:9090"
        "ws://10.67.0.1:9090"
      ];
      monitor.enable = false;
    };
  };
}
