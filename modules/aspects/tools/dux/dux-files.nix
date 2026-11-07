{ inputs, ... }: {
  den.aspects.tools.dux.files.homeManager = {
    imports = [
      inputs.dux-files.homeModules.dux-files
    ];
  };
}
