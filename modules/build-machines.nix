{username, ...}: {
  nix = {
    distributedBuilds = true;

    buildMachines = [
      {
        hostName = "195.201.39.140";
        sshUser = "root";
        sshKey = "/Users/${username}/.ssh/id_rsa";
        system = "aarch64-linux";
        supportedFeatures = [
          "aarch64-linux"
          "kvm"
          "big-parallel"
        ];
      }
    ];
  };

  programs.ssh.knownHosts = {
    "195.201.39.140".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcsxyrD9ha0lnu2i/QIFz1LpnCObCS+tO/cO542Jy/U";
  };
}
