{
  pkgs,
  username,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    alejandra
  ];

  home.file.".config/nvim/init.lua".source = ./nvim/init.lua;
  home.file.".config/nvim/lua".source = ./nvim/lua;
}
