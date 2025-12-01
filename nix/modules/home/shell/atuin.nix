{ ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    enableFishIntegration = false;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.keyruu.de";
    };
  };
}
