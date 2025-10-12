{ pkgs, config, ... }:
{
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        # backend = "iwd";
        # powersave = true;
      };
    };

    firewall.enable = true;
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      Cache=no
    '';
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.NetworkManager-dispatcher.enable = false;

  users.users."${config.user.name}".extraGroups = [ "networkmanager" ];

  environment.systemPackages = with pkgs; [ wirelesstools ];
}
