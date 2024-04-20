{...}: {
  services.sketchybar = {
    enable = true;
    config = builtins.readFile ./sktechybarrc.sh;
  };
}
