{
  pkgs,
  lib,
  ...
}:
let
  beetsPath = "/etc/stacks/beets";
  beetsConfigPath = "${beetsPath}/config.yaml";
  beetsDbPath = "${beetsPath}/beets.db";
  downloadPath = "/main/media/Music/downloads/completed";
  musicPath = "/main/media/Music/library";

  beetsConfig = {
    directory = musicPath;
    library = beetsDbPath;

    plugins = [
      "fetchart"
      "lyrics"
      "lastgenre"
      "embedart"
      "duplicates"
    ];

    terminal_encoding = "utf-8";

    threaded = true;

    ui = {
      color = true;
    };

    import = {
      write = true;
      copy = false;
      move = false;
      hardlink = true;
      autotag = true;
      bell = true;
      log = "/dev/null";
    };

    original_date = true;
    per_disc_numbering = true;

    embedart = {
      auto = true;
    };

    paths = {
      default = "$albumartist/($year) $album %aunique{}/$track $title %aunique{}";
      singleton = "$albumartist/($year) $album %aunique{}/$track $title %aunique{}";
      comp = "Compilations/$album %aunique{}/$track $title %aunique{}";
    };

    aunique = {
      keys = [
        "albumartist"
        "album"
      ];
      disambiguators = [
        "albumtype"
        "year"
        "label"
        "catalognum"
        "albumdisambig"
        "releasegroupdisambig"
      ];
      bracket = "[]";
    };

    fetchart = {
      auto = true;
      sources = [
        "filesystem"
        "coverart"
        "itunes"
        "amazon"
        "albumart"
        "fanarttv"
      ];
    };

    lastgenre = {
      auto = true;
      source = "album";
    };
  };

  beetsConfigYaml = pkgs.lib.generators.toYAML { } beetsConfig;
in
{
  environment.etc."stacks/beets/config.yaml".text = beetsConfigYaml;

  systemd.services.beets = {
    enable = true;
    description = "Automatically import and organize downloads using beets";
    path = [ pkgs.beets ];
    after = [ "network.target" ];
    environment = {
      "BEETSDIR" = beetsPath;
    };
    serviceConfig = {
      Type = "oneshot";
      ReadOnlyPaths = [ beetsConfigPath ];
      ReadWritePaths = [
        downloadPath
        musicPath
        beetsPath
      ];
      ExecStart =
        let
          beets-import = pkgs.writeScriptBin "beets-import" ''
            #!${lib.getExe pkgs.bash}
            ${lib.getExe pkgs.beets} -c ${beetsConfigPath} update
            ${lib.getExe pkgs.beets} -c ${beetsConfigPath} import -s -q ${downloadPath}
            ${lib.getExe pkgs.tmpwatch} 6h ${downloadPath}
          '';
        in
        lib.getExe beets-import;
    };
  };
}
