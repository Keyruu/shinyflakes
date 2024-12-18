{
  inputs,
  username,
  ...
}: {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim

    ./common.nix
    ./firefox.nix
    ./neovim.nix
    ./borders.nix
    ./yabai.nix
    ./skhd.nix
    ./sketchybar.nix
    ./intellij.nix
    ./kubie.nix
    ./shell
    ./programs
    ./aerospace.nix
    ./bin.nix
    ./ssh.nix
    ./kanata.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "23.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
