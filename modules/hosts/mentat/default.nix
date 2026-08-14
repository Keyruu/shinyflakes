{
  den,
  config,
  ...
}:
{
  # Mentat: home server. Mesh server, ZFS NAS, runs every self-hosted service.
  den.hosts.x86_64-linux.mentat = {
    users.root.classes = [ ];

    # Mesh identity on host entity. Mentat is mesh-reachable as a peer
    # at 100.67.0.2; allowedIPs lets it route the LAN through the mesh.
    mesh = {
      ip = config.den.people.lucas.devices.mentat.ip;
      publicKey = "nDCk5Y9nEaoV51hLDGCjzlRyglAx/UcH9v1W9F9/imw=";
      allowedIPs = [ "192.168.100.0/24" ];
    };
  };

  den.aspects.mentat = {
    mesh-device = { host, ... }: host.mesh // { name = "mentat"; };

    nixos = { lib, ... }: {
      # define-user battery (in den.schema.host.includes) sets
      # users.users.root.isNormalUser = true and home = "/home/root",
      # both wrong for root (uid 0, home should be /root). Override.
      users.users.root = {
        isSystemUser = lib.mkForce true;
        isNormalUser = lib.mkForce false;
        home = lib.mkForce "/root";
      };
    };

    includes = [
      # Core (every host) — pulled in via modules/users/root.nix's
      # `den.aspects.core` include. Don't add the individual core aspects
      # here; that would cause duplicate definitions (e.g. kernel.sysctl
      # set twice).

      # Server infrastructure
      # Note: den.aspects.server.headless lives in modules/users/root.nix —
      # it's a per-user aspect, not a per-host one. Including it here
      # would cause duplicate users.users.root.shell definitions.
      den.aspects.server.ssh-access
      den.aspects.server.comin
      den.aspects.server.beszel-agent
      den.aspects.server.cert
      den.aspects.server.backup
      den.aspects.server.nas
      # nginx + ACME acceptTerms (used by copyparty, syncthing, blocky-ui,
      # calibre-web, paperless, etc. for direct nginx vhosts)
      den.aspects.server.nginx
      den.aspects.server.nginx-extras
      # Mesh firewall: nftables forward rules for all peer devices.
      # (Uses topLevelConfig.den.people captured in outer let.)
      den.aspects.server.mesh-firewall
      # Monitoring infrastructure: declares services.monitoring options,
      # wires up cadvisor + comin.exporter + node_exporter + fluent-bit.
      # The actual dashboards live in monitoring.nix below.
      den.aspects.server.monitoring-infra
      den.aspects.server.monitoring

      # Prime-side consumers included on mentat for local eval only
      # (prime is not a den-managed host).
      den.aspects.server.public-proxy
      den.aspects.server.dashboard
      den.aspects.server.authelia

      # Services
      den.aspects.services.cockpit
      den.aspects.services.syncthing
      den.aspects.services.copyparty
      den.aspects.services.glance
      den.aspects.services.harmonia
      den.aspects.services.renovate
      den.aspects.services.print
      den.aspects.services.forgejo-notify
      den.aspects.services.forgejo-runner
      den.aspects.services.blocky
      den.aspects.services.actualbudget
      den.aspects.services.backrest
      den.aspects.services.calibre-web
      den.aspects.services.changedetection
      den.aspects.services.forgejo
      den.aspects.services.hermes
      den.aspects.services.hytale
      den.aspects.services.home-assistant
      den.aspects.services.isponsorblocktv
      den.aspects.services.karakeep
      den.aspects.services.karaoke
      den.aspects.services.media
      den.aspects.services.paperless
      den.aspects.services.radicale
      den.aspects.services.speedtest-tracker
      den.aspects.services.terraria
      den.aspects.services.traccar
      den.aspects.services.immich
    ];
  };
}
