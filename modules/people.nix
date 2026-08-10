# Seed data for the people registry.
#
# Three people:
#   - lucas:  admin, owns 6 NixOS-managed hosts + phone. Static group: admin.
#   - nadine: guest, 2 unmanaged devices (laptop, handy). Static group: user.
#   - simon:  guest, 2 unmanaged devices (pc, pc2). Static group: user.
#
# Managed host devices (mentat, thopter, muadib, carryall, lighter) are
# ALSO declared on their host entities via modules/hosts/<host>/mesh.nix
# as the `mesh-device` quirk. The den.people.<name>.devices list here
# covers them too (for authelia / nftables consumers that need the
# person→device mapping); the mesh-server collects peers from the
# `mesh-device` quirk only.
#
# ponytail: this duplicates the legacy `services.mesh.people` registry
# in nix/modules/services/mesh/people.nix. During additive migration
# both are kept in sync manually. Delete the legacy file when the last
# consumer migrates.
{
  den.people = {
    lucas = {
      email = "lucas@keyruu.de";
      displayname = "Lucas";
      staticGroups = [ "admin" ];
      service-access = [
        "immich"
        "karakeep"
        "paperless"
        "jellyfin"
        "traccar"
        "chatto"
        "gotify"
        "seerr"
      ];
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
        lighter = {
          ip = "100.67.0.11";
          publicKey = "XljZyy4r96qP/8WHwzjruGqX/RShWDXkT431ppT9cQw=";
        };
      };
    };
    nadine = {
      email = "nadine.october664@slmail.me";
      displayname = "Nadine";
      staticGroups = [ "user" ];
      service-access = [
        "traccar"
        "chatto"
        "jellyfin"
        "seerr"
      ];
      devices = {
        laptop = {
          ip = "100.67.0.9";
          publicKey = "fpD7FpLgrvDn+AkoBTdD0sypjyaOnLZYCFpO3AGL2yU=";
        };
        handy = {
          ip = "100.67.0.10";
          publicKey = "P3NhS9iNpINQqqIpjg0wbGJkJD122TkLYs4pCFSW9jU=";
        };
      };
    };
    simon = {
      email = "gluecksmann.simon@gmx.de";
      displayname = "Simon";
      staticGroups = [ "user" ];
      service-access = [
        "chatto"
        "jellyfin"
        "seerr"
      ];
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
  };
}
