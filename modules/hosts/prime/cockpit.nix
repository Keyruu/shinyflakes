{
  den.aspects.prime.nixos = {
    services.my.cockpit = {
      domain = "prime.keyruu.de";
      origins = [
        "http://100.67.0.1:9090"
        "ws://100.67.0.1:9090"
      ];
      monitor.enable = false;
    };
  };
}
