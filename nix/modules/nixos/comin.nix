{
  config,
  inputs,
  pkgs,
  ...
}:
let
  comin-notify = pkgs.writeShellApplication {
    name = "comin-notify";
    runtimeInputs = [ pkgs.gotify-cli ];
    text = ''
      GOTIFY_TOKEN=$(cat ${config.sops.secrets.cominGotifyToken.path})
      export GOTIFY_TOKEN

      if [ "$COMIN_STATUS" = "success" ]; then
        TITLE="Deployment Success: $COMIN_HOSTNAME"
        PRIORITY=4
        MESSAGE="Host: $COMIN_HOSTNAME
      Status: $COMIN_STATUS
      Git SHA: $COMIN_GIT_SHA
      Git Ref: $COMIN_GIT_REF
      Commit: $COMIN_GIT_MSG
      Flake URL: $COMIN_FLAKE_URL
      Generation: $COMIN_GENERATION"
      else
        TITLE="Deployment Failed: $COMIN_HOSTNAME"
        PRIORITY=8
        MESSAGE="Host: $COMIN_HOSTNAME
      Status: $COMIN_STATUS
      Git SHA: $COMIN_GIT_SHA
      Git Ref: $COMIN_GIT_REF
      Commit: $COMIN_GIT_MSG
      Flake URL: $COMIN_FLAKE_URL
      Generation: $COMIN_GENERATION
      Error: $COMIN_ERROR_MSG"
      fi

      gotify push \
        --url "https://notify.keyruu.de" \
        --title "$TITLE" \
        --priority "$PRIORITY" \
        "$MESSAGE"
    '';
  };
in
{
  imports = [
    inputs.comin.nixosModules.comin
  ];

  sops.secrets = {
    cominForgejoToken = { };
    cominGotifyToken = { };
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

    postDeploymentCommand = "${comin-notify}/bin/comin-notify";
  };
}
