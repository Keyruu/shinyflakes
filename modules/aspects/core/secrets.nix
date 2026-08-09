{ inputs, ... }:
{
  den.aspects.core.secrets = {
    nixos = { config, pkgs, ... }: {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      environment.systemPackages = with pkgs; [
        sops
      ];

      environment.sessionVariables = {
        SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/keys.txt";
      };

      sops = {
        defaultSopsFile = ../../../nix/secrets.yaml;
        age.keyFile = "/var/lib/sops-nix/keys.txt";
      };
    };
    homeManager = { config, ... }: {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops = {
        defaultSopsFile = ../../nix/secrets.yaml;
        age = {
          keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          # sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
      };
    };
  };
}
