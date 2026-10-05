{ ... }:
{
  den.aspects.shell.ssh = {
    homeManager = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            ControlPath = "~/.ssh/_%C";
            ControlMaster = "no";
          };
          "github.com" = {
            HostName = "ssh.github.com";
            Port = 443;
            User = "git";
          };
          "dash0" = {
            HostName = "ssh.github.com";
            Port = 443;
            User = "git";
            IdentityFile = "~/.ssh/dash0_ed25519";
            IdentitiesOnly = true;
          };
          "prime" = {
            HostName = "168.119.225.165";
            User = "root";
            Compression = true;
          };
        };
      };
    };
  };
}
