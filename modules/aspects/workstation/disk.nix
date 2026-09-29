{ inputs, ... }: {
  den.aspects.workstation.disk.nixos = { ... }: {
    imports = [
      inputs.disko.nixosModules.disko
    ];

    fileSystems."/persist".neededForBoot = true;
    fileSystems."/var/log".neededForBoot = true;
  };
}
