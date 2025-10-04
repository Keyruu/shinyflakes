{ ... }:
{
  programs.zed-editor = {
    enable = true;

    extensions = [
      "material-icon-theme"
      "nix"
      "helm"
      "scala"
    ];
  };
}
