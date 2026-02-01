{
  config,
  pkgs,
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
    sops.secrets.deployToken = { };

    networking.firewall.interfaces = lib.genAttrs config.services.deploy-webhook.interfaces (_: {
      allowedTCPPorts = [ config.services.webhook.port ];
    });

    systemd.services.webhook.serviceConfig = {
      User = lib.mkForce "root";
      Group = lib.mkForce "root";
    };

    services.webhook = {
      enable = true;
      package = perSystem.self.webhook;
      openFirewall = false;
      port = 8565;
      hooksTemplated =
        let
          deployScript =
            pkgs.writeShellScript "deploy-script" # sh
              ''
                set -euo pipefail

                /run/wrappers/bin/sudo ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch --flake ${config.services.deploy-webhook.flake}
              '';
        in
        {
          deploy-template = # json
            ''
              {
                "id": "deploy",
                "execute-command": "${deployScript}",
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
