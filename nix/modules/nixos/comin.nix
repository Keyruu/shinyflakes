{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.comin.nixosModules.comin
  ];

  sops = {
    secrets = {
      resendApiKey = { };
      cominForgejoToken = { };
    };
    templates."forgejoCreds".content =
      "https://x-access-token:${config.sops.placeholder.cominForgejoToken}@git.keyruu.de";
  };

  programs.git.config = {
    credential."https://git.keyruu.de" = {
      helper = "store --file ${config.sops.templates."forgejoCreds".path}";
    };
  };

  services.comin = {
    enable = true;
    hostname = config.networking.hostName;
    submodules = true;
    remotes = [
      {
        name = "origin";
        url = "https://git.keyruu.de/lucas/shinyflakes.git";
        auth = {
          username = "x-access-token";
          access_token_path = config.sops.secrets.cominForgejoToken.path;
        };
        branches.main.name = "main";
      }
    ];

    postDeploymentCommand = pkgs.writers.writeBash "comin-notify" ''
      RESEND_API_KEY=$(cat ${config.sops.secrets.resendApiKey.path})

      if [ "$COMIN_STATUS" = "success" ]; then
        STATUS_EMOJI="✅"
        STATUS_TEXT="Success"
      else
        STATUS_EMOJI="❌"
        STATUS_TEXT="Failed"
      fi

      RESEND_BODY=$(cat <<EOF
      {
        "from": "comin@lab.keyruu.de",
        "to": ["me@keyruu.de"],
        "subject": "$STATUS_EMOJI Comin Deployment $STATUS_TEXT: $COMIN_HOSTNAME",
        "html": "<html><body style='font-family: monospace;'>
          <h2>$STATUS_EMOJI Deployment $STATUS_TEXT</h2>
          <table style='border-collapse: collapse;'>
            <tr><td style='padding: 8px; font-weight: bold;'>Hostname:</td><td style='padding: 8px;'>$COMIN_HOSTNAME</td></tr>
            <tr><td style='padding: 8px; font-weight: bold;'>Status:</td><td style='padding: 8px;'>$COMIN_STATUS</td></tr>
            <tr><td style='padding: 8px; font-weight: bold;'>Git SHA:</td><td style='padding: 8px;'><code>$COMIN_GIT_SHA</code></td></tr>
            <tr><td style='padding: 8px; font-weight: bold;'>Git Ref:</td><td style='padding: 8px;'>$COMIN_GIT_REF</td></tr>
            <tr><td style='padding: 8px; font-weight: bold;'>Commit Message:</td><td style='padding: 8px;'>$COMIN_GIT_MSG</td></tr>
            <tr><td style='padding: 8px; font-weight: bold;'>Flake URL:</td><td style='padding: 8px;'><code>$COMIN_FLAKE_URL</code></td></tr>
            <tr><td style='padding: 8px; font-weight: bold;'>Generation:</td><td style='padding: 8px;'>$COMIN_GENERATION</td></tr>
            $(if [ -n "$COMIN_ERROR_MSG" ]; then echo "<tr><td style='padding: 8px; font-weight: bold; color: red;'>Error:</td><td style='padding: 8px; color: red;'><pre>$COMIN_ERROR_MSG</pre></td></tr>"; fi)
          </table>
        </body></html>"
      }
      EOF
      )

      ${pkgs.curl}/bin/curl -X POST https://api.resend.com/emails \
        -H "Authorization: Bearer $RESEND_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$RESEND_BODY"
    '';
  };
}
