{ flake, ... }:
let
  inherit (flake.lib.kanshi) monitors moveAllToOne moveAllWorkspaces;
in
{
  imports = [ flake.homeModules.default ];

  services.kanshi.settings = [
    {
      profile = {
        name = "tuxedo";
        outputs = [ (monitors.tuxedo // { position = "0,0"; }) ];
        exec = [ (moveAllToOne monitors.tuxedo.criteria) ];
      };
    }
    {
      profile = {
        name = "tuxedo-home";
        outputs = [
          (monitors.tuxedo // { position = "0,0"; })
          (monitors.home // { position = "-320,-1440"; })
        ];
        exec = [ (moveAllWorkspaces monitors.home.criteria monitors.tuxedo.criteria) ];
      };
    }
  ];
}
