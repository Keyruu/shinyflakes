_: {
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
      "prime" = {
        HostName = "168.119.225.165";
        User = "root";
        Compression = true;
      };
    };
  };
}
