{ config, lib, ... }:
{
  services.syncthing = {
    enable = true;

    user = lib.mkDefault config.user.name;
    dataDir = lib.mkDefault "/home/${config.user.name}";

    openDefaultPorts = true;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      options.urAccepted = -1;

      devices = {
        fairphone.id = "32BRNST-FVHJCGH-JJXLLZD-5B7DXEG-FJHOYKE-YJV7MCY-6I4NOB4-HJYBFA5";
        muadib.id = "2X36LHE-IOQZGKU-G7B53FJ-ILY6TMU-QXQSHLV-C7PIQ4U-JZUVITM-KV37FAB";
        mentat.id = "RR5NKJX-GZGJ22Z-OC5MA3P-HEAGZK6-QD7CHUK-TNARPTX-H7OCUBD-URI7MAO";
      };

      folders =
        let
          dir = config.services.syncthing.dataDir;
        in
        {
          git = {
            enable = lib.mkDefault true;
            path = "${dir}/git";
            devices = [
              "mentat"
              # "thopter"
              # "carryall"
              "muadib"
              "fairphone"
            ];
            ignorePerms = false;
          };
          documents = {
            enable = lib.mkDefault true;
            path = "${dir}/documents";
            devices = [
              "mentat"
              # "thopter"
              # "carryall"
              "muadib"
              "fairphone"
            ];
          };
          work = {
            enable = lib.mkDefault true;
            path = "${dir}/work";
            devices = [
              "mentat"
              # "thopter"
              # "carryall"
              "muadib"
            ];
            ignorePerms = false;
          };
          obsidian = {
            enable = lib.mkDefault true;
            path = "${dir}/obsidian";
            devices = [
              "mentat"
              # "thopter"
              # "carryall"
              "muadib"
              "fairphone"
            ];
          };
        };
    };
  };
}
