{ pkgs, config, ... }:
{
  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi = {
        # backend = "iwd";
        scanRandMacAddress = false; # Can help with faster reconnection
        powersave = false; # Disable power saving for faster connections
      };
    };

    firewall.enable = true;

    hosts = {
      "0.0.0.0" = [ "apresolve.spotify.com" ];
    };
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
