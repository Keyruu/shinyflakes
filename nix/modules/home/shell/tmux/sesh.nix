{ ... }:
{
  programs.sesh = {
    enable = true;
    enableTmuxIntegration = false;
    settings = {
      session = [
        {
          name = "shinyflakes";
          path = "~/shinyflakes";
        }
        {
          name = "git";
          path = "~/git";
        }
        {
          name = "home";
          path = "~";
        }
      ];
      wildcard = [
        { pattern = "~/git/*"; }
      ];
    };
  };
}
