{ config, ... }:
{
  launchd.agents.kanata = {
    serviceConfig = {
      ProgramArguments = [
        "sudo"
        "/opt/homebrew/bin/kanata"
        "--cfg"
        "/Users/${config.user.name}/.config/kanata/default.kbd"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/kanata.log";
      StandardErrorPath = "/tmp/kanata.err";
    };
  };
}
