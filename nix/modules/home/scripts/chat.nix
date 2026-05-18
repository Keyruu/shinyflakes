{ pkgs, lib, ... }:
let
  chat = pkgs.writeShellApplication {
    name = "chat";
    runtimeInputs = [ pkgs.niri ];
    text = ''
      glide-browser --new-window "https://app.slack.com" "https://discord.com/app" "https://open.spotify.com" &
      sleep 1
      niri msg action move-window-to-workspace "social" --focus false
      niri msg action set-column-width "66%"
    '';
  };
in
{
  home.packages = [ chat ];

  xdg.desktopEntries.chat = {
    name = "Chat";
    exec = "${lib.getExe chat}";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" "Chat" ];
    icon = "internet-chat";
    comment = "Open Slack and Discord in Glide";
  };
}
