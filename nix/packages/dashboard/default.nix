{
  pkgs,
}:
let
  lib = pkgs.lib;

  # icons from homarr-labs/dashboard-icons (jsDelivr CDN)
  # ponytail: skip the auto-lookup table; just hardcode what each service uses.
  # if a service is missing here, fall back to a generic icon.
  fallback = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png";
  di = name: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/${name}.svg";

  # apps list. groups = [] means visible to all authed users.
  # ponytail: the list lives here in the package, not the host module, so
  # `nix build .#dashboard` just works. to add/remove an app, edit this attrset.
  apps = [
    # --- everyone (empty groups) ---
    {
      title = "Glance";
      description = "At-a-glance status board";
      url = "https://glance.lab.keyruu.de";
      icon = di "glance";
      groups = [ ];
    }
    {
      title = "Chatto";
      description = "Chat";
      url = "https://chat.peeraten.net";
      icon = fallback;
      groups = [ ];
    }
    {
      title = "Jellyfin";
      description = "Media server";
      url = "https://tv.peeraten.net";
      icon = di "jellyfin";
      groups = [ ];
    }
    {
      title = "Seerr";
      description = "Media requests";
      url = "https://requests.peeraten.net";
      icon = di "seerr";
      groups = [ ];
    }

    # --- shared: lucas + nadine ---
    {
      title = "Traccar";
      description = "GPS tracking";
      url = "https://traccar.peeraten.net";
      icon = di "traccar";
      groups = [ "traccar_users" ];
    }

    # --- lucas only ---
    {
      title = "Cockpit";
      description = "Server admin";
      url = "https://mentat.lab.keyruu.de";
      icon = di "cockpit";
      groups = [ "lucas" ];
    }
    {
      title = "Forgejo";
      description = "Git hosting";
      url = "https://git.keyruu.de";
      icon = di "forgejo";
      groups = [ "lucas" ];
    }
    {
      title = "Backrest";
      description = "Restic backup UI";
      url = "https://backrest.lab.keyruu.de";
      icon = di "backrest";
      groups = [ "lucas" ];
    }
    {
      title = "Immich";
      description = "Photo library";
      url = "https://immich.lab.keyruu.de";
      icon = di "immich";
      groups = [ "immich_users" ];
    }
    {
      title = "Paperless";
      description = "Document archive";
      url = "https://paperless.lab.keyruu.de";
      icon = di "paperless";
      groups = [ "paperless_users" ];
    }
    {
      title = "Karakeep";
      description = "Bookmarks";
      url = "https://karakeep.lab.keyruu.de";
      icon = di "karakeep";
      groups = [ "karakeep_users" ];
    }
    {
      title = "Gotify";
      description = "Push notifications";
      url = "https://notify.keyruu.de";
      icon = di "gotify";
      groups = [ "gotify_users" ];
    }
  ];

  renderCard = app: ''
    <a class="card" href="${app.url}" data-groups="${lib.concatStringsSep " " app.groups}"${lib.optionalString (app.newTab or false) " target=\"_blank\" rel=\"noopener noreferrer\""}>
      <img class="icon" src="${app.icon}" alt="" loading="lazy">
      <div class="text">
        <span class="title">${app.title}</span>
        ${lib.optionalString (app ? description && app.description != null) "<span class=\"desc\">${app.description}</span>"}
      </div>
    </a>
  '';

  cards = lib.concatMapStringsSep "\n        " renderCard apps;

  # ponytail: per-group CSS rules hide unauthorized cards before first paint,
  # no JS flicker. substring selector works because group names don't collide
  # (no group is a substring of another). add a new group anywhere → it shows
  # up here automatically.
  allGroups = lib.unique (lib.concatMap (a: a.groups) apps);
  hideRules = lib.concatMapStringsSep "\n"
    (g: ''body:not([data-user-groups*="${g}"]) .card[data-groups~="${g}"] { display: none; }'')
    allGroups;
  styleCss = builtins.readFile ./style.css + "\n" + hideRules;

  indexHtml = ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <title>Dashboard</title>
      <link rel="stylesheet" href="/style.css">
    </head>
    <body data-user-name="{{.Req.Header.Get "Remote-Name"}}" data-user-groups="{{.Req.Header.Get "Remote-Groups"}}">
      <header>
        <h1>Dashboard</h1>
        <p id="user"></p>
      </header>
      <main class="grid" id="grid">
        ${cards}
      </main>
      <p id="empty" hidden>No apps available for your groups.</p>
      <script src="/app.js"></script>
    </body>
    </html>
  '';
in
pkgs.runCommand "dashboard" { } ''
  mkdir -p $out
  cp ${pkgs.writeText "style.css" styleCss} $out/style.css
  cp ${./app.js} $out/app.js
  cat > $out/index.html <<'HTML'
  ${indexHtml}
  HTML
''
