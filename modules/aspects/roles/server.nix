{ den, ... }:
{
  den.aspects.roles.server = {
    role = "server";
    includes = [
      den.aspects.server.comin
      den.aspects.server.cert
      den.aspects.server.beszel-agent
      den.aspects.server.headless
      den.aspects.server.ssh-access

      den.aspects.options.backup
      den.aspects.options.monitoring
      den.aspects.options.my.services
      den.aspects.options.my.stack
    ];
  };
}
