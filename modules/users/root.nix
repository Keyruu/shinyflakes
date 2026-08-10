{ den, ... }:
{
  den.aspects.root = { host, ... }: {
    includes = [
      den.aspects.core

      den.aspects.server.comin
      den.aspects.server.beszel-agent
      den.aspects.server.headless
      den.aspects.server.ssh-access

      den.aspects.options.my.services
      den.aspects.options.my.stack
      den.aspects.options.monitoring
      den.aspects.options.backup
    ];
  };
}
