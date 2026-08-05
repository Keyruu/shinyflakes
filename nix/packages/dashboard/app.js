// ponytail: card visibility handled by CSS (per-group rules generated in
// default.nix), so unauthorized cards are hidden before first paint.
// this script only handles the two edges CSS can't: user name and empty state.

const userEl = document.getElementById("user");
const emptyEl = document.getElementById("empty");

const userName = document.body.dataset.userName || "";
if (userName) userEl.textContent = `Signed in as ${userName}`;

const anyVisible = [...document.querySelectorAll(".card")]
  .some((c) => getComputedStyle(c).display !== "none");
if (!anyVisible) emptyEl.hidden = false;
