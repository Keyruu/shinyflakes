{
  den,
  ...
}:
{
  # Mentat: home server. Mesh server, ZFS NAS, runs every self-hosted service.
  den.hosts.x86_64-linux.mentat.users.root.classes = [ ];

  den.aspects.mentat = {
    includes = [
      den.aspects.roles.server

      den.aspects.tools.syncthing

      den.aspects.server.backup
      den.aspects.server.nginx
      den.aspects.server.monitoring

      # Services
      den.aspects.services.cockpit
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
      den.aspects.services.home-assistant.default
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
