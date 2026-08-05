// ponytail: caddy templates inject __USER_GROUPS__ / __USER_NAME__ before this
// runs (forward_auth copies Remote-* headers onto the request, templates reads them).

const userEl = document.getElementById("user");
const emptyEl = document.getElementById("empty");

const userGroups = (window.__USER_GROUPS__ || "")
  .split(/\s+/)
  .filter(Boolean);
const userName = window.__USER_NAME__ || "";

if (userName) userEl.textContent = `Signed in as ${userName}`;

let visible = 0;
document.querySelectorAll(".card").forEach((card) => {
  const required = (card.dataset.groups || "").split(/\s+/).filter(Boolean);
  // empty groups = visible to all authed users
  const allowed =
    required.length === 0 || required.some((g) => userGroups.includes(g));
  if (allowed) visible++;
  else card.hidden = true;
});

if (visible === 0) emptyEl.hidden = false;
