{ ... }:
{
  home.file.".config/bin" = {
    source = ./bin;
    recursive = true;
    executable = true;
  };
}
