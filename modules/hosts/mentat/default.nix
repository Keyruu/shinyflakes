{
  den,
  ...
}:
{
  # Lucas laptop. First den-native host, no blueprint equivalent.
  den.hosts.x86_64-linux.mentat.users.root.classes = [ ];

  den.aspects.mentat = {
    includes = [
      den.aspects.services.immich
      den.aspects.server.gatus
      den.aspects.server.prometheus
    ];
  };
}
