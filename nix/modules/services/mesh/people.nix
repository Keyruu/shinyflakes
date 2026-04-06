{ lib, config, ... }:
{
  options.services.mesh = {
    networks = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        home = "192.168.100.0/24";
        nas = "192.168.100.7/32";
      };
      description = "Named networks that can be referenced in canAccess";
    };
    people = lib.mkOption {
      type =
        with lib.types;
        attrsOf (submodule {
          options = {
            canAccess = lib.mkOption {
              type = listOf str;
              default = [ ];
              description = "List of network names from services.mesh.networks";
            };

            devices = lib.mkOption {
              type = attrsOf (submodule {
                options = {
                  ip = lib.mkOption {
                    type = str;
                  };
                  publicKey = lib.mkOption {
                    type = str;
                  };
                  allowedIPs = lib.mkOption {
                    type = listOf str;
                    default = [ ];
                  };
                };
              });
              default = { };
            };
          };
        });
      default = { };
    };
    zones = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          attrsOf (submodule {
            options = {
              ip = lib.mkOption { type = str; };
              publicKey = lib.mkOption { type = str; };
              allowedIPs = lib.mkOption {
                type = listOf str;
                default = [ ];
              };
            };
          })
        );
      default = { };
    };
  };

  config =
    let
      allDevices = lib.concatLists (
        lib.mapAttrsToList (
          personName: person:
          lib.mapAttrsToList (
            deviceName: device: {
              inherit (device) ip;
              label = "${personName}.${deviceName}";
            }
          ) person.devices
        ) config.services.mesh.people
      );

      allIPs = map (d: d.ip) allDevices;

      # Validate IP format: must be a valid IPv4 address without subnet mask
      isValidIPv4 = ip:
        let
          hasSlash = builtins.match ".*/.+" ip != null;
          parts = builtins.match "([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)" ip;
          octets = if parts != null then map lib.toInt parts else [ ];
          octetsValid = builtins.all (o: o >= 0 && o <= 255) octets;
        in
        !hasSlash && parts != null && octetsValid;

      invalidDevices = builtins.filter (d: !(isValidIPv4 d.ip)) allDevices;
      formatInvalid = lib.concatStringsSep "\n" (
        map (d: "  ${d.label}: ${d.ip}") invalidDevices
      );
    in
    {
      assertions = [
        {
          assertion = allIPs == lib.unique allIPs;
          message = "Duplicate IPs detected in the mesh!";
        }
        {
          assertion = invalidDevices == [ ];
          message = ''
            Invalid IPs detected in services.mesh.people!
            IPs must be valid IPv4 addresses without subnet masks:
            ${formatInvalid}
          '';
        }
      ];
      services.mesh = {
        networks = {
          home = "192.168.100.0/24";
          nas = "192.168.100.7/32";
        };
        people = {
          simon = {
            canAccess = [ "nas" ];
            devices = {
              pc = {
                ip = "100.67.0.5";
                publicKey = "oE4JGoMZgRzPChGqaXCSl9K2O82M15p00Xe65hwKMi8=";
              };
              pc2 = {
                ip = "100.67.0.7";
                publicKey = "LFFnUgPpO34BYNULUBaHmC4esZae0MXU4KsJ8txXsHU=";
              };
            };
          };
          nadine = {
            canAccess = [ "home" ];
            devices = {
              laptop = {
                publicKey = "fpD7FpLgrvDn+AkoBTdD0sypjyaOnLZYCFpO3AGL2yU=";
                ip = "100.67.0.9";
              };
              handy = {
                publicKey = "P3NhS9iNpINQqqIpjg0wbGJkJD122TkLYs4pCFSW9jU=";
                ip = "100.67.0.10";
              };
            };
          };
          lucas = {
            canAccess = [ "home" ];
            devices = {
              mentat = {
                ip = "100.67.0.2";
                publicKey = "nDCk5Y9nEaoV51hLDGCjzlRyglAx/UcH9v1W9F9/imw=";
                allowedIPs = [ "192.168.100.0/24" ];
              };
              phone = {
                ip = "100.67.0.3";
                publicKey = "7FBclS8OV86p7IYYAKHnjm0dl+e9ImvMvh7+lLnOCyk=";
              };
              thopter = {
                ip = "100.67.0.4";
                publicKey = "PL5/3dK1BeIxoJufy51QHjMFQOq7SFR7WZ0sLmjqZW4=";
              };
              muadib = {
                ip = "100.67.0.6";
                publicKey = "dBpryxEEqSYKnaMjdStm/cqf7R3QtlWNZDQnr4dKek4=";
              };
              carryall = {
                ip = "100.67.0.8";
                publicKey = "7Qn12iKEGxRNIEAOkoKQ2FUXKzvWWEP6ORJ3IHJ/sBI=";
              };
            };
          };
        };
      };
    };
}
