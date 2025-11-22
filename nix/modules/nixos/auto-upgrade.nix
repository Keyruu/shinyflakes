{
  config,
  ...
}:
{
  imports = [
    ./services/auto-upgrade-notify.nix
  ];

  sops.secrets.resendApiKey = { };

  services.autoUpgradeNotify = {
    enable = true;
    flake = "github:Keyruu/shinyflakes";
    dates = "*:0/5";
    resendApiKeyPath = config.sops.secrets.resendApiKey.path;
    fromEmail = "nixos-upgrade@lab.keyruu.de";
    toEmails = [ "me@keyruu.de" ];
  };
}
