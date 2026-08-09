// ponytail: card visibility handled by CSS (per-group rules generated in
// default.nix), so unauthorized cards are hidden before first paint.
// this script only handles the two edges CSS can't: user name and empty state.

// authelia sends Remote-Groups as comma-separated; CSS ~= needs whitespace.
// normalize once on load so the per-group selectors match cleanly.
const groups = (document.body.dataset.userGroups || "")
  .split(",")
  .map((g) => g.trim())
  .filter(Boolean)
  .join(" ");
document.body.dataset.userGroups = groups;

const userEl = document.getElementById("user");
const emptyEl = document.getElementById("empty");

const userName = document.body.dataset.userName || "";
if (userName) userEl.textContent = `Signed in as ${userName}`;

const anyVisible = [...document.querySelectorAll(".card")]
  .some((c) => getComputedStyle(c).display !== "none");
if (!anyVisible) emptyEl.hidden = false;