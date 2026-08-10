{ den, ... }: {
  den.aspects.shell = {
    includes = with den.aspects.shell; [
      fish
      ssh
      tmux
      zellij
      zsh
    ];
  };
}
