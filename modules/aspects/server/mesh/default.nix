{ den, ... }:
{
  den.aspects.server.mesh = {
    includes = [
      den.aspects.server.mesh.server
      den.aspects.server.mesh.firewall
    ];
  };
}
