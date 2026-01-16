{ lib, ... }:
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

  config.services.mesh = {
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
        };
      };
      # nadine = {
      # };
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
        };
      };
    };
  };
}
