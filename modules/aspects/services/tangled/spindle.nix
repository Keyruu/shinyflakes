{ inputs, ... }:
{
  den.aspects.services.tangled.spindle = {
    nixos =
      {
        config,
        lib,
        inputs',
        ...
      }:
      let
        my = config.services.my.tangled-spindle;
        domain = "spindle.keyruu.de";
        did = "did:plc:tslldt2xzl33vemmc7ikjtz7";

        tangledPkgs = inputs'.tangled.packages;
        # upstream links go-sqlite3 against a sqlite amalgamation shipped as
        # a .zip flake input, which nix cannot unpack (only already-fetched
        # copies work), so drop the libsqlite3 tag and let go-sqlite3 build
        # its own bundled copy instead.
        # shortcut: loses the shared libsqlite3, revisit when upstream ships a tarball
        spindle = tangledPkgs.spindle.overrideAttrs (_: {
          tags = [ ];
          env = {
            CGO_CFLAGS = "";
            CGO_LDFLAGS = "-L ${tangledPkgs.hydrant-ffi}/lib";
          };
        });
      in
      {
        imports = [ inputs.tangled.nixosModules.spindle ];

        sops.secrets.spindleKey = { };

        services.tangled.spindle = {
          enable = true;
          package = spindle;
          # did:web signing key; it lives in sops because losing it makes
          # other services distrust the spindle until they re-resolve it
          keyPath = config.sops.secrets.spindleKey.path;
          contact.email = "me@keyruu.de";
          server = {
            hostname = domain;
            owner = did;
            listenAddr = "${config.services.mesh.ip}:${toString my.port}";
            # the box also runs every other service; one VM at a time
            maxJobCount = 1;
          };
          artifactStores.s3.bucket = "";
          pipelines.microvm.limits = {
            total = {
              memoryMiB = 6144;
              vcpus = 4;
            };
            workflow = {
              memoryMiB = 4096;
              vcpus = 2;
            };
          };
        };

        # workflows boot the nixos microVM image from here
        systemd.tmpfiles.rules = [
          "d /var/lib/spindle/images 0755 root root -"
          "L+ /var/lib/spindle/images/nixos - - - - ${tangledPkgs.spindle-nixos-image}"
        ];

        # the module forces docker on for nixery pipelines, but this box runs
        # podman with dockerCompat, which owns the docker socket (nixpkgs
        # asserts they cannot coexist). microVM workflows need no docker;
        # nixery ones are unavailable here.
        virtualisation.docker.enable = lib.mkForce false;

        networking.firewall.allowedTCPPorts = [ my.port ];

        services.my.tangled-spindle = {
          title = "Tangled spindle";
          description = "CI runners for tangled repos";
          port = 6555;
          inherit domain;
          dashboard = {
            groups = [ "admin" ];
            icon = "https://cdn.simpleicons.org/tangled";
          };
          monitor.healthPath = "/_health";
          backup = {
            enable = true;
            paths = [ "/var/lib/spindle" ];
            # stopping the spindle waits out its 20 min run drain on every backup
            systemd.enable = false;
          };
        };
      };
  };
}
