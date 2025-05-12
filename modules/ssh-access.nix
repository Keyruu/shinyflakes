{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    htop
    btop
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      ClientAliveInterval = 60;
    };
  };

  networking.firewall.allowedTCPPorts = [22];

  services.fail2ban.enable = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAST8ufT97SIVy9JI9AWNnO7Gx+/Q/+lCdaovcUhz8sR lucas@stern"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO9dWkivgasUCTazyqJ6qiCNoYo0xR6nR4NPyz/DuG3A lucas@nixos"
  ];
}
