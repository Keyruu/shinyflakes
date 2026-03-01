{ flake, inputs, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
in
rec {
  quadletToService = container: builtins.replaceStrings [ ".container" ] [ ".service" ] container.ref;

  _getImages =
    hostName:
    let
      host = inputs.self.nixosConfigurations.${hostName} or null;
      containers = if host != null then host.config.virtualisation.quadlet.containers else { };
    in
    lib.mapAttrsToList (name: cfg: {
      host = hostName;
      container = name;
      inherit (cfg.containerConfig) image;
    }) containers;

  allImages = lib.flatten (
    map _getImages [
      "mentat"
      "prime"
    ]
  );

  hostMatrix = {
    host = builtins.attrNames flake.nixosConfigurations;
  };
}
