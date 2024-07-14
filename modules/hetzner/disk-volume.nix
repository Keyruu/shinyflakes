{
  id,
  mountpoint,
  ...
}: {
  disko.devices.disk = {
    # hetzner block storage, must be attached from cloud gui
    block = {
      device = "/dev/disk/by-id/scsi-0HC_Volume_${id}";
      type = "disk";
      content = {
        type = "filesystem";
        format = "ext4";
        inherit mountpoint;
      };
    };
  };
}
