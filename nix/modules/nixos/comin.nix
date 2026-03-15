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

      status="''${COMIN_STATUS:-unknown}"
      hostname="''${COMIN_HOSTNAME:-unknown}"
      gitRef="''${COMIN_GIT_REF:-}"
      gitMsg="''${COMIN_GIT_MSG:-}"
      generation="''${COMIN_GENERATION:-}"
      errorMsg="''${COMIN_ERROR_MSG:-}"

      if [ "$status" = "done" ]; then
        title="Deployment Success: $hostname"
        priority=4
        message="Host: $hostname
      Status: $status
      Git Ref: $gitRef
      Commit: $gitMsg
      Generation: $generation"
      else
        title="Deployment Failed: $hostname"
        priority=8
        message="Host: $hostname
      Status: $status
      Git Ref: $gitRef
      Commit: $gitMsg
      Generation: $generation
      Error: $errorMsg"
      fi

      if ! gotify push \
        --url "https://notify.keyruu.de" \
        --title "$title" \
        --priority "$priority" \
        "$message"; then
        echo "Failed to send gotify notification" >&2
      fi
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
