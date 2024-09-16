// A very tridactyl-esque config file.

// Compatibility Prefix
const {
  Clipboard,
  Front,
  Hints,
  Normal,
  RUNTIME,
  Visual,
  aceVimMap,
  addSearchAlias,
  cmap,
  getClickableElements,
  imap,
  imapkey,
  iunmap,
  map,
  mapkey,
  readText,
  removeSearchAlias,
  tabOpenLink,
  unmap,
  unmapAllExcept,
  vmapkey,
  vunmap
} = api;

// ---- Settings ----
Hints.setCharacters('asdfgyuiopqwertnmzxcvb');

settings.hintAlign = 'left';
settings.focusFirstCandidate = false;
settings.focusAfterClosed = 'last';
settings.scrollStepSize = 200;
settings.tabsThreshold = 0;
settings.modeAfterYank = 'Normal';

// ---- Map -----
// --- Hints ---
// Open Multiple Links
map('<Alt-f>', 'cf');

// Yank Link URL
map('<Alt-y>', 'ya');
map('<Alt-u>', 'ya');

// Open Hint in new tab
map('F', 'C');

// --- Nav ---
// Open Clipboard URL in current tab
mapkey('p', "Open the clipboard's URL in the current tab", () => { Clipboard.read(function(response) { window.location.href = response.data; }); });

// Open Clipboard URL in new tab
map('P', 'cc');

// Open a URL in current tab
map('o', 'go');

// Choose a buffer/tab
map('b', 'T');

// Edit current URL, and open in same tab
map('O', ';U');

// Edit current URL, and open in new tab
map('T', ';u');

// History Back/Forward
map('H', 'S');
map('L', 'D');

// Scroll Page Down/Up
mapkey("<Ctrl-d>", "Scroll down", () => { Normal.scroll("pageDown"); });
mapkey("<Ctrl-u>", "Scroll up", () => { Normal.scroll("pageUp"); });
map('<Ctrl-b>', 'U');  // scroll full page up
//map('<Ctrl-f>', 'P');  // scroll full page down -- looks like we can't overwrite browser-native binding

// Next/Prev Page
map('K', '[[');
map('J', ']]');

// Open Chrome Flags
mapkey('gF', '#12Open Chrome Flags', () => { tabOpenLink("chrome://flags/"); });

// --- Tabs ---
// Tab Delete/Undo
map('D', 'x');
mapkey('d', '#3Close current tab', () => { RUNTIME("closeTab"); });
mapkey('u', '#3Restore closed tab', () => { RUNTIME("openLast"); });

// Move Tab Left/Right w/ one press
map('>', '>>');
map('<', '<<');

// Tab Next/Prev
map('<Alt-j>', 'R');
map('<Alt-k>', 'E');

// --- Misc ---
// Yank URL w/ one press (disables other yx binds)
map('y', 'yy');

// Change focused frame
map('gf', 'w');

// ---- Unmap -----
// Proxy Stuff
// unmap('spa');
// unmap('spb');
// unmap('spc');
// unmap('spd');
// unmap('sps');
// unmap('cp');
// unmap(';cp');
// unmap(';ap');

// Emoji
// iunmap(":");

// Misc
// unmap(';t');
// unmap('si');
// unmap('ga');
// unmap('gc');
// unmap('gn');
// unmap('gr');
// unmap('ob');
// unmap('og');
// unmap('od');
// unmap('oy');

// ---- Search Engines -----
removeSearchAlias('b', 's');
removeSearchAlias('d', 's');
removeSearchAlias('g', 's');
removeSearchAlias('h', 's');
removeSearchAlias('w', 's');
removeSearchAlias('y', 's');
removeSearchAlias('s', 's');

addSearchAlias('d', 'ddg', 'https://duckduckgo.com/?q=', 's');
addSearchAlias('dh', 'docker', 'https://hub.docker.com/search?type=image&q=', 's');
addSearchAlias('gh', 'github', 'https://github.com/search?q=', 's');
addSearchAlias('s', 'startpage', 'https://www.startpage.com/sp/search?q=', 's')
addSearchAlias('np', 'nixos packages', 'https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=', 's')
addSearchAlias('no', 'nixos options', 'https://search.nixos.org/options?channel=unstable&size=50&sort=relevance&type=packages&query=', 's')
addSearchAlias('nh', 'nix home-manager', 'https://home-manager-options.extranix.com/?release=master&query=', 's')

// ---- Hints ----
// Hints have to be defined separately
// Uncomment to enable

// Tomorrow-Night
Hints.style('border: solid 2px #373B41; color:#52C196; background: initial; background-color: #1D1F21;');
Hints.style("border: solid 2px #373B41 !important; padding: 1px !important; color: #C5C8C6 !important; background: #1D1F21 !important;", "text");
Visual.style('marks', 'background-color: #52C19699;');
Visual.style('cursor', 'background-color: #81A2BE;');

settings.theme = `
/* Edit these variables for easy theme making */
:root {
  /* Font */
  --font: 'JetBrainsMono Nerd Font', Ubuntu, sans;
  --font-size: 14;
  --font-weight: bold;

  /* -------------- */
  /* --- THEMES --- */
  /* -------------- */

  /* -------------------- */
  /* -- Tomorrow Night -- */
  /* -------------------- */
  --fg: #C5C8C6;
  --bg: #282A2E;
  --bg-dark: #1D1F21;
  --border: #373b41;
  --main-fg: #81A2BE;
  --accent-fg: #52C196;
  --info-fg: #AC7BBA;
  --select: #585858;
}

/* ---------- Generic ---------- */
.sk_theme {
background: var(--bg);
color: var(--fg);
  background-color: var(--bg);
  border-color: var(--border);
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
}

input {
  font-family: var(--font);
  font-weight: var(--font-weight);
}

.sk_theme tbody {
  color: var(--fg);
}

.sk_theme input {
  color: var(--fg);
}

/* Hints */
#sk_hints .begin {
  color: var(--accent-fg) !important;
}

#sk_tabs .sk_tab {
  background: var(--bg-dark);
  border: 1px solid var(--border);
}

#sk_tabs .sk_tab_title {
  color: var(--fg);
}

#sk_tabs .sk_tab_url {
  color: var(--main-fg);
}

#sk_tabs .sk_tab_hint {
  background: var(--bg);
  border: 1px solid var(--border);
  color: var(--accent-fg);
}

.sk_theme #sk_frame {
  background: var(--bg);
  opacity: 0.2;
  color: var(--accent-fg);
}

/* ---------- Omnibar ---------- */
/* Uncomment this and use settings.omnibarPosition = 'bottom' for Pentadactyl/Tridactyl style bottom bar */
/* .sk_theme#sk_omnibar {
  width: 100%;
  left: 0;
} */

.sk_theme .title {
  color: var(--accent-fg);
}

.sk_theme .url {
  color: var(--main-fg);
}

.sk_theme .annotation {
  color: var(--accent-fg);
}

.sk_theme .omnibar_highlight {
  color: var(--accent-fg);
}

.sk_theme .omnibar_timestamp {
  color: var(--info-fg);
}

.sk_theme .omnibar_visitcount {
  color: var(--accent-fg);
}

.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
  background: var(--bg-dark);
}

.sk_theme #sk_omnibarSearchResult ul li.focused {
  background: var(--border);
}

.sk_theme #sk_omnibarSearchArea {
  border-top-color: var(--border);
  border-bottom-color: var(--border);
}

.sk_theme #sk_omnibarSearchArea input,
.sk_theme #sk_omnibarSearchArea span {
  font-size: var(--font-size);
}

.sk_theme .separator {
  color: var(--accent-fg);
}

/* ---------- Popup Notification Banner ---------- */
#sk_banner {
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
  background: var(--bg);
  border-color: var(--border);
  color: var(--fg);
  opacity: 0.9;
}

/* ---------- Popup Keys ---------- */
#sk_keystroke {
  background-color: var(--bg);
}

.sk_theme kbd .candidates {
  color: var(--info-fg);
}

.sk_theme span.annotation {
  color: var(--accent-fg);
}

/* ---------- Popup Translation Bubble ---------- */
#sk_bubble {
  background-color: var(--bg) !important;
  color: var(--fg) !important;
  border-color: var(--border) !important;
}

#sk_bubble * {
  color: var(--fg) !important;
}

#sk_bubble div.sk_arrow div:nth-of-type(1) {
  border-top-color: var(--border) !important;
  border-bottom-color: var(--border) !important;
}

#sk_bubble div.sk_arrow div:nth-of-type(2) {
  border-top-color: var(--bg) !important;
  border-bottom-color: var(--bg) !important;
}

/* ---------- Search ---------- */
#sk_status,
#sk_find {
  font-size: var(--font-size);
  border-color: var(--border);
}

.sk_theme kbd {
  background: var(--bg-dark);
  border-color: var(--border);
  box-shadow: none;
  color: var(--fg);
}

.sk_theme .feature_name span {
  color: var(--main-fg);
}

/* ---------- ACE Editor ---------- */
#sk_editor {
  background: var(--bg-dark) !important;
  height: 50% !important;
  /* Remove this to restore the default editor size */
}

.ace_dialog-bottom {
  border-top: 1px solid var(--bg) !important;
}

.ace-chrome .ace_print-margin,
.ace_gutter,
.ace_gutter-cell,
.ace_dialog {
  background: var(--bg) !important;
}

.ace-chrome {
  color: var(--fg) !important;
}

.ace_gutter,
.ace_dialog {
  color: var(--fg) !important;
}

.ace_cursor {
  color: var(--fg) !important;
}

.normal-mode .ace_cursor {
  background-color: var(--fg) !important;
  border: var(--fg) !important;
  opacity: 0.7 !important;
}

.ace_marker-layer .ace_selection {
  background: var(--select) !important;
}

.ace_editor,
.ace_dialog span,
.ace_dialog input {
  font-family: var(--font);
  font-size: var(--font-size);
  font-weight: var(--font-weight);
}
`;
