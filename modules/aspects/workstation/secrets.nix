{ inputs, ... }:
{
  den.aspects.workstation.secrets =
    let
      keyFile = user: "/home/${user.name}/.config/sops/age/keys.txt";
    in
    {
      nixos =
        {
          user,
          pkgs,
          ...
        }:
        {
          imports = [
            inputs.sops-nix.nixosModules.sops
          ];

          environment.systemPackages = with pkgs; [
            sops
          ];

          environment.sessionVariables = {
            SOPS_AGE_KEY_FILE = keyFile user;
          };

          sops = {
            defaultSopsFile = ../../../secrets.yaml;
            age.keyFile = keyFile user;
          };
        };

      homeManager = { user, ... }: {
        imports = [
          inputs.sops-nix.homeManagerModules.sops
        ];

        sops = {
          defaultSopsFile = ../../../secrets.yaml;
          age = {
            keyFile = keyFile user;
            # sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          };
        };
      };
    };
}
