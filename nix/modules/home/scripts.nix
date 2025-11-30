{ ... }:
{
  home.file.".config/bin" = {
    source = ./scripts;
    recursive = true;
    executable = true;
  };
}
