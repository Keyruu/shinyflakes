{
  pkgs,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "nirius";
  version = "0.5.4";

  # src = pkgs.fetchFromGitHub {
  #   owner = "Keyruu";
  #   repo = "nirius";
  #   rev = "c6363b3c446c40627124abe7ff942113943d24b4";
  #   hash = "sha256-CSKmM/SGoKZm4Oub8HfBCE8Vx91NVLZ4auOWDdKMQrc=";
  # };
  src = pkgs.fetchFromSourcehut {
    owner = "~tsdh";
    repo = "nirius";
    rev = "5b36e83ad4890df3f26d6cf461c5bb6b36b305fb";
    hash = "sha256-TbK6Tq3yFsD6Bn1Hy6aEoGCnH1/Wbu+VUGahjVgQz2Q=";
  };

  cargoHash = "sha256-eLQf3cC95y4UdPI/gJWN4Fdwa3DqXT+QvIV+2w34ul0=";

  meta = {
    description = "Utility commands for the niri wayland compositor";
    mainProgram = "nirius";
    homepage = "https://git.sr.ht/~tsdh/nirius";
    license = pkgs.lib.licenses.gpl3Plus;
    maintainers = with pkgs.lib.maintainers; [ tylerjl ];
    platforms = pkgs.lib.platforms.linux;
  };
}
