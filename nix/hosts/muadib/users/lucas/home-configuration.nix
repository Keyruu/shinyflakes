{ flake, ... }:
let
  inherit (flake.lib.kanshi) monitors moveAllToOne moveAllWorkspaces;
in
{
  imports = [ flake.homeModules.default ];

  services.kanshi.settings = [
    {
      profile = {
        name = "desktop-home";
        outputs = [ (monitors.home // { position = "0,0"; }) ];
        exec = [ (moveAllToOne monitors.home.criteria) ];
      };
    }
    {
      profile = {
        name = "desktop-home-side";
        outputs = [
          (monitors.home // { position = "0,0"; })
          (monitors.side // { position = "2560,720"; })
        ];
        exec = [ (moveAllWorkspaces monitors.home.criteria monitors.side.criteria) ];
      };
    }
  ];
}
