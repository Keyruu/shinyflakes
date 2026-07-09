{ flake, ... }:
let
  inherit (flake.lib.kanshi) monitors moveAllToOne moveAllWorkspaces;
in
{
  imports = [ flake.homeModules.default ];

  services.kanshi.settings = [
    {
      profile = {
        name = "laptop";
        outputs = [ (monitors.laptop // { position = "0,0"; }) ];
        exec = [ (moveAllToOne monitors.laptop.criteria) ];
      };
    }
    {
      profile = {
        name = "laptop-home";
        outputs = [
          (monitors.laptop // { position = "0,0"; })
          (monitors.home // { position = "-320,-1440"; })
        ];
        exec = [ (moveAllWorkspaces monitors.home.criteria monitors.laptop.criteria) ];
      };
    }
    {
      profile = {
        name = "laptop-work";
        outputs = [
          (monitors.laptop // { position = "0,0"; })
          (monitors.work // { position = "-411,-1543"; })
        ];
        exec = [ (moveAllWorkspaces monitors.work.criteria monitors.laptop.criteria) ];
      };
    }
  ];
}
