{...}: {
  programs.ssh = {
    enable = true;
    controlPath = "~/.ssh/%C";
    matchBlocks = {
      "sleipnir" = {
        hostname = "168.119.225.165";
        user = "root";
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
