{
  nixpkgs.overlays = [
    (_: super: {makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});})
  ];

  # makes the sdImage a .img instead of .img.zst
  sdImage.compressImage = false;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };
}
