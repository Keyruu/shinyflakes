{ den, ... }: {
  den.aspects.terminals.default = {
    includes = with den.aspects.terminals; [
      ghostty
      kitty
    ];
  };
}
