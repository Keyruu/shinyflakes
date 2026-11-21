{ den, ... }:
{
  # Tangled's self-hosted pieces: a knot stores git, a spindle runs CI.
  # bobbin (the appview/index) and the web frontend are not hosted yet.
  den.aspects.services.tangled = {
    includes = [
      den.aspects.services.tangled.knot
      den.aspects.services.tangled.spindle
    ];
  };
}
