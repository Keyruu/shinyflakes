{ den, ... }: {
  den.aspects.terminals.default = {
    includes = with den.aspects.terminals; [
      foot
      ghostty
      kitty
    ];
  };
}
