{ lib, pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    settings = {
      hooks = {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${lib.getExe pkgs.libnotify} 'Claude Code' 'I am done!' -i cog";
              }
            ];
          }
        ];
        Notification = [
          {
            hooks = [
              {
                type = "command";
                command = "${lib.getExe pkgs.libnotify} 'Claude Code' 'I need your help!' -i cog";
              }
            ];
          }
        ];
      };
    };
  };
}
