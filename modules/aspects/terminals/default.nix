{ den, ... }: {
  den.aspects.terminals = {
    includes = with den.aspects.terminals; [
      foot
      ghostty
      kitty
    ];
  };
}
