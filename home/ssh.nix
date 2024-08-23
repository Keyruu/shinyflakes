{...}: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "sleipnir" = {
        hostname = "168.119.225.165";
        user = "root";
      };
      "hati" = {
        hostname = "192.168.187.18";
        user = "root";
      };
      "truenas" = {
        hostname = "192.168.187.16";
        user = "root";
      };
      "fenrir" = {
        hostname = "192.168.187.14";
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
      "deere.github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "%d/.ssh/jd-github";
      };
    };
    extraConfig = ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };
}
