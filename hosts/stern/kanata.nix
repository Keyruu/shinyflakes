{ pkgs, username, ... }:
{
  launchd.agents.kanata = {
    serviceConfig = {
      ProgramArguments = [
        "sudo"
        "/opt/homebrew/bin/kanata"
        "--cfg"
        "/Users/${username}/.config/kanata/default.kbd"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/kanata.log";
      StandardErrorPath = "/tmp/kanata.err";
    };
  };
}
