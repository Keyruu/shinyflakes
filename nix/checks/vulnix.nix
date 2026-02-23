{
  inputs,
  pkgs,
  system,
  ...
}:
let
  # filter hosts that match the architecture we are currently checking
  relevantHosts = pkgs.lib.filterAttrs (
    _: host: host.pkgs.system == system
  ) inputs.self.nixosConfigurations;
in
pkgs.runCommand "vulnix-all-hosts"
  {
    nativeBuildInputs = [ pkgs.vulnix ];
  }
  ''
    echo "Starting Vulnix scan for systems on ${system}..."
    ${pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (name: host: ''
        echo "Scanning host: ${name}"
        vulnix --system ${host.config.system.build.toplevel} || true 
      '') relevantHosts
    )}
    touch $out
  ''
