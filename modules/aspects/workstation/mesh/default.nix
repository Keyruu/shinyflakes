{ den, ... }:
{
  den.aspects.workstation.mesh = {
    includes = [
      den.aspects.workstation.mesh.client
    ];
  };
}
