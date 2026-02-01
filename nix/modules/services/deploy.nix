{
  config,
  perSystem,
  lib,
  ...
}:
{
  options.services.deploy-webhook = {
    enable = lib.mkEnableOption "enable deploy webhook";

    flake = lib.mkOption {
      type = lib.types.str;
      example = "github:user/repo";
      description = "The flake URL to upgrade from";
    };

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "eth0" ];
      description = "The interfaces where the port of the webhook will be exposed";
    };
  };

  config = lib.mkIf config.services.deploy-webhook.enable {
    users = {
      groups.webhook.gid = 1021;
      users = {
        webhook = {
          isSystemUser = true;
          uid = 1021;
          group = "webhook";
        };
      };
    };

    sops.secrets.deployToken = {
      owner = "webhook";
      group = "webhook";
    };

    networking.firewall.interfaces = lib.genAttrs config.services.deploy-webhook.interfaces (_: {
      allowedTCPPorts = [ config.services.webhook.port ];
    });

    services.webhook = {
      enable = true;
      package = perSystem.self.webhook;
      openFirewall = false;
      port = 8565;
      hooksTemplated = {
        deploy-template = # json
          ''
            {
              "id": "deploy",
              "execute-command": "${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch --flake ${config.services.deploy-webhook.flake}",
              "include-command-output-in-response": true,
              "include-command-output-in-response-on-error": true,
              "trigger-rule": {
                "match": {
                  "type": "value",
                  "value": "{{ cat "${config.sops.secrets.deployToken.path}" }}",
                  "parameter": {
                    "source": "header",
                    "name": "X-Deploy-Token"
                  }
                }
              }
            }
          '';
      };
    };
  };
}
