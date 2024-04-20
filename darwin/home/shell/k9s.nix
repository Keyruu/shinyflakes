{...}: {
  programs.k9s = {
    enable = true;
    aliases = {
      aliases = {
        ss = "statefulsets";
      };
    };
  };
}
