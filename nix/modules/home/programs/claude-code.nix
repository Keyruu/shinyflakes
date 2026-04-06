{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  small = import inputs.nixpkgs-small {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home.packages = with pkgs; [
    claude-code-router
  ];

  programs.claude-code = {
    enable = true;
    package = small.claude-code;
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
