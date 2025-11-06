{
  inputs,
  pkgs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  services.vicinae = {
    enable = true;
    autoStart = true;
    useLayerShell = false;
    package = perSystem.vicinae.default;
    extensions = [
      # (inputs.vicinae.mkVicinaeExtension.${pkgs.system} {
      #   inherit pkgs;
      #   name = "vicinae-bluetooth";
      #   src = pkgs.fetchgit {
      #     url = "https://codeberg.org/gelei/vicinae-bluetooth";
      #     rev = "16204787e0ac3925e7e466df38f3a959294b440f";
      #     hash = "sha256-xOemsBLnXKfcCVOZew2vm0mlylfFvcX4s/AnpjF3kBo=";
      #   };
      # })
      # (inputs.vicinae.mkVicinaeExtension.${pkgs.system} {
      #   inherit pkgs;
      #   name = "wifi-commander";
      #   src =
      #     pkgs.fetchFromGitHub {
      #       owner = "dagimg-dot";
      #       repo = "j-vicinae-extensions";
      #       rev = "ec83fde026b856e52b1c8835a923e8dd168d9e3f";
      #       sha256 = "sha256-yirdUhHEJ9tNQoPubMJHUBwOpXFOevjqyaJlcW3+d5I=";
      #     }
      #     + "/extensions/wifi-commander";
      # })
    ];
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
