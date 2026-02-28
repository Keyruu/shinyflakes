{
  ...
}:
{
  # imports = [
  #   flake.modules.services.auto-upgrade-notify
  # ];
  #
  # sops.secrets.resendApiKey = { };

  system.autoUpgrade = {
    enable = true;
    flake = "github:Keyruu/shinyflakes";
    dates = "*:0/5";
    # resendApiKeyPath = config.sops.secrets.resendApiKey.path;
    # fromEmail = "nixos-upgrade@lab.keyruu.de";
    # toEmails = [ "me@keyruu.de" ];
  };
}
