_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        controlPath = "~/.ssh/_%C";
        controlMaster = "no";
      };
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
      };
      "prime" = {
        hostname = "168.119.225.165";
        user = "root";
        compression = true;
      };
      "coolify" = {
        hostname = "195.201.39.140";
        user = "root";
      };
      "traversetown" = {
        hostname = "78.47.122.5";
        user = "root";
      };
    };
  };
}
