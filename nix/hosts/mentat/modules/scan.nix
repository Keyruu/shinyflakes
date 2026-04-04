{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  my = config.services.my.scanservjs;
  scansPath = "${my.stack.path}/scans";

  # FIXME: remove nixpkgs-scanservjs pin once https://github.com/NixOS/nixpkgs/pull/492318 is merged
  pkgs-scanservjs = import inputs.nixpkgs-scanservjs { inherit (pkgs.stdenv.hostPlatform) system; };
  nadineConsumePath = "/mnt/nadine-paperless";
in
{
  hardware.sane.brscan4.enable = true;

  environment.systemPackages = [ pkgs.cifs-utils ];

  sops = {
    secrets = {
      nadineSmbUsername = { };
      nadineSmbPassword = { };
    };

    templates."nadine-smb-credentials" = {
      content = ''
        username=${config.sops.placeholder.nadineSmbUsername}
        password=${config.sops.placeholder.nadineSmbPassword}
      '';
    };
  };

  fileSystems.${nadineConsumePath} = {
    device = "//192.168.100.31/documents/consume";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."nadine-smb-credentials".path}"
      "uid=scanservjs"
      "gid=scanservjs"
      "file_mode=0770"
      "dir_mode=0770"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };

  services.my.scanservjs = {
    port = 8070;
    domain = "scan.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        {
          path = "scans/lucas";
          owner = "scanservjs";
          group = "scanservjs";
        }

      ];
    };
  };

  # FIXME: remove once https://github.com/NixOS/nixpkgs/pull/492318 is merged
  # scanservjs expects data/preview/default.jpg relative to its working directory
  # but the file lives in the nix store
  systemd.services.scanservjs.serviceConfig.ExecStartPre = [
    "+${pkgs.coreutils}/bin/mkdir -p /var/lib/scanservjs/data/preview"
    "+${pkgs.coreutils}/bin/ln -sf ${pkgs-scanservjs.scanservjs}/lib/data/preview/default.jpg /var/lib/scanservjs/data/preview/default.jpg"
  ];

  services.scanservjs = {
    enable = true;
    settings = {
      host = "127.0.0.1";
      inherit (my) port;
    };
    extraActions = [
      ''
        {
          name: 'Send to Lucas',
          async execute(fileInfo) {
            const Process = require('${pkgs-scanservjs.scanservjs}/lib/server/classes/process');
            return await Process.spawn("cp '" + fileInfo.fullname + "' '${scansPath}/lucas/'");
          }
        }
      ''
      ''
        {
          name: 'Send to Nadine',
          async execute(fileInfo) {
            const Process = require('${pkgs-scanservjs.scanservjs}/lib/server/classes/process');
            return await Process.spawn("cp '" + fileInfo.fullname + "' '${nadineConsumePath}/'");
          }
        }
      ''
    ];
  };
  # FIXME: remove once https://github.com/NixOS/nixpkgs/pull/492318 is merged
  systemd.services.scanservjs.serviceConfig.ExecStart = lib.mkForce (
    lib.getExe pkgs-scanservjs.scanservjs
  );
}
