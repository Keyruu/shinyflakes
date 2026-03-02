{ config, ... }:
{
  nix = {
    distributedBuilds = true;

    buildMachines = [
      {
        hostName = "192.168.100.7";
        sshUser = "root";
        sshKey = "/home/${config.user.name}/.ssh/id_ed25519";
        system = "x86_64-linux";
        maxJobs = 40;
        speedFactor = 2;
        supportedFeatures = [
          "kvm"
          "big-parallel"
        ];
      }
    ];
  };

  programs.ssh.knownHosts = {
    "192.168.100.7".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnXQvd4ITKTnx1+0kWDobgECK8fa09a3xPSj8jsk/XT";
  };
}
