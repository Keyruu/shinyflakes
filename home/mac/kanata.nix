{
  pkgs,
  username,
  ...
}:
let
  kanata =
    pkgs.writeShellScriptBin "my-kanata" # sh
      ''
        sh - c "/opt/homebrew/bin/kanata --cfg /Users/${username}/.config/kanata/default.kbd > /tmp/kanata.log"
      '';
in
{
  home.file.".config/kanata/default.kbd".source = ../common/kanata.kbd;

  launchd.agents.kanata = {
    enable = false;
    config = {
      # Program = "/opt/homebrew/bin/kanata";
      UserName = username;
      ProgramArguments = [
        "/opt/homebrew/bin/kanata"
        "--cfg"
        "/Users/${username}/.config/kanata/default.kbd"
      ];
      StandardOutPath = "/tmp/kanata.out";
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
