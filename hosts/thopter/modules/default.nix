{pkgs, ...}: {
  imports = [
    ./audio.nix
    ./1password.nix
  ];

  programs = {
    nix-ld.enable = true;
    kdeconnect.enable = true;
    firefox.enable = true;
    fish.enable = true;
    hyprland.enable = true;
    ydotool.enable = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    neovim
    lshw
    wezterm
    git
    kitty
    evtest
    wev
  ];

  services.kanata = {
    enable = true;
    keyboards.lenovo.configFile = ../../../home/common/kanata.kbd;
  };
}
