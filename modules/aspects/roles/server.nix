{ den, inputs, ... }:
{
  den.aspects.roles.server = {
    role = "server";
    includes = [
      den.aspects.core.default

      den.aspects.server.comin
      den.aspects.server.cert
      den.aspects.server.beszel-agent
      den.aspects.server.headless
      den.aspects.server.ssh-access

      den.aspects.options.backup
      den.aspects.options.cloudflare
      den.aspects.options.monitoring
      den.aspects.options.my.services
      den.aspects.options.my.stack
    ];
    nixos =
      {
        lib,
        ...
      }:
      {
        imports = [
          inputs.sops-nix.nixosModules.sops
        ];

        sops = {
          defaultSopsFile = ../../../secrets.yaml;
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };

        # users.users.root.isSystemUser = true;
        # users.users.root.isNormalUser = lib.mkForce false;
      };
  };
}
