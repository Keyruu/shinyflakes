{
  den,
  ...
}:
{
  den.hosts.x86_64-linux.prime.users.root.classes = [ ];

  den.aspects.prime = {
    nixos = { ... }: {
      services.mesh.ip = "100.67.0.1";
    };

    includes = [
      den.aspects.roles.server

      den.aspects.server.hetzner

      den.aspects.server.cert
      den.aspects.server.caddy

      den.aspects.server.mesh-server

      den.aspects.server.authelia
      den.aspects.server.dashboard
      den.aspects.server.proxy
      den.aspects.server.public-proxy
      den.aspects.server.webpages
      den.aspects.server.frp
      den.aspects.server.edge-protection
      den.aspects.server.blog-redirects
      den.aspects.services.cockpit

      # Stacks running on prime.
      den.aspects.services.gotify
      den.aspects.services.liwan
      den.aspects.services.multi-scrobbler
      den.aspects.services.chatto
      den.aspects.services.koito
    ];
  };
}
