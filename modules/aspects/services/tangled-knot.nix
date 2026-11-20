{ inputs, ... }:
{
  den.aspects.services.tangled-knot = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.tangled-knot;
        domain = "knot.keyruu.de";
      in
      {
        imports = [ inputs.tangled.nixosModules.knot-rs ];

        sops.secrets.knotMasterKey = { };

        # The knot unseals its signing keys with this one value; losing it
        # makes the sealed key store in /var/lib/knot unreadable.
        sops.templates."knot.env" = {
          owner = "knot";
          restartUnits = [ "knot-rs.service" ];
          content = ''
            KNOT_MASTER_KEY=${config.sops.placeholder.knotMasterKey}
          '';
        };

        services.tangled.knot-rs = {
          enable = true;
          environmentFile = config.sops.templates."knot.env".path;
          settings = {
            server = {
              hostname = domain;
              admins = [ "did:plc:tslldt2xzl33vemmc7ikjtz7" ];
              # prime's caddy is the only public entry point and reaches this
              # over the mesh; 5555 is karaoke on mentat
              listen_addr = "${config.services.mesh.ip}:${toString my.port}";
              # Cloudflare cannot carry SSH and mentat has no public address,
              # so SSH is LAN-only: knot.lab.keyruu.de resolves to mentat for
              # home clients (blocky), and clone over
              # ssh://git@knot.lab.keyruu.de:2222/<did>/<repo>.
              ssh_listen_addr = "[::]:2222";
            };
            atproto.plc_directory = "https://plc.directory";
            lfs.store_path = "/var/lib/knot/lfs";
            contact.email = "me@keyruu.de";
            xrpc = {
              # prime's caddy is the only hop in front of the knot
              trusted_proxy_header = "x-forwarded-for";
              trusted_proxies = [ "10.67.0.1" ];
            };
          };
        };

        services.my.tangled-knot = {
          title = "Tangled knot";
          description = "Git repositories served over atproto";
          port = 5556;
          inherit domain;
          dashboard = {
            groups = [ "admin" ];
            icon = "https://cdn.simpleicons.org/tangled";
          };
          monitor.healthPath = "/xrpc/_health";
          backup = {
            enable = true;
            paths = [ "/var/lib/knot" ];
            systemd.unit = "knot-rs.service";
          };
        };
      };
  };
}
