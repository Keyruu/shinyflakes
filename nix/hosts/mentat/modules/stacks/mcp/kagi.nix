{
  config,
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  ssePort = 30004;
  oapiPort = 30104;
in
{
  sops.secrets = {
    kagiApiKey = { };
  };

  sops.templates."mcp-kagi.env" = {
    restartUnits = [
      "mcp-kagi.service"
      "mcpo-kagi.service"
    ];
    content = ''
      KAGI_API_KEY=${config.sops.placeholder.kagiApiKey}
      KAGI_SUMMARIZER_ENGINE=cecil
    '';
  };

  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [ ssePort ];
    "${config.services.mesh.interface}".allowedTCPPorts = [ ssePort ];
    ai.allowedTCPPorts = [ oapiPort ];
  };

  systemd.services.mcp-kagi = {
    description = "mcp-kagi";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${toString ssePort} --host 0.0.0.0 --pass-environment -- ${pkgs.uv}/bin/uvx kagimcp";
      EnvironmentFile = config.sops.templates."mcp-kagi.env".path;
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };

  # systemd.services.mcpo-kagi = {
  #   description = "mcpo-kagi";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = "${lib.getExe perSystem.self.mcpo} --port ${toString oapiPort} --host 0.0.0.0 -- ${pkgs.uv}/bin/uvx kagimcp";
  #     EnvironmentFile = config.sops.templates."mcp-kagi.env".path;
  #     User = "root";
  #     Group = "root";
  #     Restart = "always";
  #   };
  # };
}
