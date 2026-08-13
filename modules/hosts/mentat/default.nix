{
  den,
config,
  ...
}:
{
  # Mentat: home server. First den-native host, no blueprint equivalent.
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

    includes = [
      den.aspects.services.immich
      den.aspects.server.gatus
      den.aspects.server.prometheus
      # Prime-side consumers, included on mentat for local eval only
      # (prime is not a den-managed host).
      den.aspects.server.public-proxy
      den.aspects.server.dashboard
      den.aspects.server.authelia
    ];
  };
}
