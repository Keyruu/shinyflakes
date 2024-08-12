{self, ...}: let
  inherit (self.inputs) deploy-rs;

  x86 = {
    sleipnir = {
      hostname = "168.119.225.165";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.sleipnir;
        fastConnection = true;
        remoteBuild = true;
      };
    };
    hati = {
      hostname = "192.168.187.18";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hati;
        fastConnection = true;
        remoteBuild = true;
      };
    };
  };
in {
  deploy.nodes = x86;
  checks = {
    x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks {nodes = x86;};
  };
}
