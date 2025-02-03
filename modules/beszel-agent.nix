{pkgs, ...}: {
  systemd.services.beszel-agent = {
    description = "Beszel Agent";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      PORT = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPF8VerHU8Y0nq8YruGK1QKRkTWisPgWa/YM5IJVc39";
    };
    serviceConfig = {
      Restart="always";
      RestartSec="5";
      User="0";
      ExecStart=''${pkgs.beszel}/bin/beszel-agent'';
    };
  };
}
