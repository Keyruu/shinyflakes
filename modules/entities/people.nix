# People entity schema — unified identity layer for mesh + authelia.
#
# Per-person data lives in modules/aspects/private/people.nix (devices, email, staticGroups,
# service-access). Auto-imported by `inputs.import-tree ./modules` in flake.nix.
{ lib, den, ... }:
let
  deviceType = lib.types.submodule {
    options = {
      ip = lib.mkOption {
        type = lib.types.str;
        example = "100.67.0.2";
      };
      publicKey = lib.mkOption {
        type = lib.types.str;
        example = "nDCk5Y9nEaoV51hLDGCjzlRyglAx/UcH9v1W9F9/imw=";
      };
      allowedIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra CIDRs to route via this peer (e.g. \"192.168.100.0/24\").";
      };
    };
  };

  peopleType = lib.types.submodule (
    { name, ... }: {
      freeformType = lib.types.attrsOf lib.types.anything;
      imports = [ den.schema.people ];

      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        aspect = lib.mkOption {
          type = lib.types.raw;
          default = if den.aspects ? ${name} then den.aspects.${name} else { };
          defaultText = "den.aspects.<name>";
          description = "Aspect that configures this person. Defaults to den.aspects.<name> if defined.";
        };
        email = lib.mkOption {
          type = lib.types.str;
          description = "Authelia login + email claim for OIDC.";
        };
        displayname = lib.mkOption {
          type = lib.types.str;
        };
        staticGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "admin" ];
          description = "Authelia groups always granted (admin, user). Service-specific groups are auto-derived from service-access grants.";
        };
        # TODO(phase 7): replace per-person canAccess with per-device canAccess on
        # the `den.devices.<sys>.<host>.<name>` entity kind (see notes/den-migration.org
        # "Mesh devices + dynamic ACLs"). Until then, mesh.nix reads this for nftables
        # forward rules; default [] = drop-all from the LAN for every device.
        canAccess = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "home"
            "nas"
          ];
          description = "Named networks (from `services.mesh.networks`) this person's devices may reach.";
        };
        devices = lib.mkOption {
          type = lib.types.attrsOf deviceType;
          default = { };
          description = "Mesh peer devices owned by this person. Each device becomes a wg peer with this pubkey/ip.";
        };
        service-access = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "immich"
            "karakeep"
          ];
          description = "Service names this person is granted access to (matches services.my.<name>). Consumed by authelia (auto-derive <svc>_users groups + policies + OIDC clients), nginx-whitelist (IP allowlist), and mesh-firewall (nftables forward rules).";
        };
      };
    }
  );
in
{
  options.den.people = lib.mkOption {
    type = lib.types.attrsOf peopleType;
    default = { };
    description = "People registry — identity + devices for mesh + authelia.";
  };

  config.den.schema.people.isEntity = true;
}
