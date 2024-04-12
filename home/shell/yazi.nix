{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      opener = {
        open = [
          {
            run = "xdg-open \"$@\"";
            orphan = true;
            desc = "Open";
          }
        ];
      };
    };
  };
}
