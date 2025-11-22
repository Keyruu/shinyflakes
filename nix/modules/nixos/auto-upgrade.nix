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
    resendApiKeyPath = config.sops.secrets.resendApiKey.path;
    fromEmail = "nixos-upgrade@lab.keyruu.de";
    toEmails = [ "me@keyruu.de" ];
  };
}
