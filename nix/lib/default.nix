_: {
  quadletToService = container: builtins.replaceStrings [ ".container" ] [ ".service" ] container.ref;
}
