{ inputs, perSystem, ... }:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  services.vicinae = {
    enable = true;
    autoStart = true;
    package = perSystem.vicinae.default;
    settings = {
      faviconService = "twenty"; # twenty | google | none
      font.size = 11;
      popToRootOnClose = false;
      rootSearch.searchFiles = false;
      theme = {
        name = "vicinae-dark";
        iconTheme = "Papirus";
      };
      window = {
        csd = true;
        opacity = 1;
        rounding = 10;
      };
    };
  };
}
