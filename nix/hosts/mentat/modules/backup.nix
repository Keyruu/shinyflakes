{ config, ... }:
{
  services.restic = {
    defaultRepo = "/main/backup/restic";
    # server = {
    #   enable = true;
    #   appendOnly = true;
    # };
  };
}
