{
  pkgs,
  apps ? [ ],
}:
let
  lib = pkgs.lib;

  fallback = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/homepage.png";

  renderCard =
    app:
    # html
    ''
      <a class="card" href="${app.url}" data-groups="${lib.concatStringsSep " " app.groups}"${
        lib.optionalString (app.newTab or false) " target=\"_blank\" rel=\"noopener noreferrer\""
      }>
        <img class="icon" src="${app.icon or fallback}" alt="" loading="lazy">
        <div class="text">
          <span class="title">${app.title}</span>
          ${lib.optionalString (
            app.description or "" != ""
          ) "<span class=\"desc\">${app.description}</span>"}
        </div>
      </a>
    '';

  cards = lib.concatMapStringsSep "\n        " renderCard apps;

  # CSS: hide all cards by default; show if user has any of the card's groups.
  # The "admin" group is added by the caller, so admin sees everything via
  # the per-group rules below. App.js normalizes the comma-separated
  # Remote-Groups to whitespace on load so CSS word-match works cleanly.
  allGroups = lib.unique (lib.concatMap (a: a.groups) apps);
  showRules = lib.concatMapStringsSep "\n" (
    g: ''body[data-user-groups~="${g}"] .card[data-groups~="${g}"] { display: flex; }''
  ) allGroups;

  # empty rule set still needs the base style; .card { display: none } lives in style.css
  styleCss = builtins.readFile ./style.css + "\n" + showRules;

  indexHtml =
    # html
    ''
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
