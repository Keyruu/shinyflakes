{ pkgs, config, ... }:
{
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi = {
        # backend = "iwd";
        # powersave = true;
      };
    };

    firewall.enable = true;
  };

  services.resolved = {
    enable = true;
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    extraConfig = ''
      Cache=yes
      CacheFromLocalhost=yes
    '';
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.NetworkManager-dispatcher.enable = false;

  users.users."${config.user.name}".extraGroups = [ "networkmanager" ];

  environment.systemPackages = with pkgs; [ wirelesstools ];
}
