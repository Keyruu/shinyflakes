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
          disable_startup_command = true;
        }
        {
          name = "home";
          path = "~";
          disable_startup_command = true;
        }
      ];
      wildcard = [
        { pattern = "~/git/*"; }
      ];
    };
  };
}
