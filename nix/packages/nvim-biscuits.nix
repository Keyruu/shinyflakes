{
  pkgs,
  ...
}:
pkgs.vimUtils.buildVimPlugin {
  name = "nvim-biscuits";
  src = pkgs.fetchFromGitHub {
    owner = "code-biscuits";
    repo = "nvim-biscuits";
    rev = "1caf9c3efa8b4c7c76c5595adfaa308034a3d985";
    hash = "sha256-UKolssxC+cfQ9x3Mum/mKPVY8jJBs6+DtQgvvufLFAk=";
  };
  dependencies = [ pkgs.vimPlugins.plenary-nvim ];
}
