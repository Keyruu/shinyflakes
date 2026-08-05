// ponytail: caddy forward_auth injects X-User-Groups / X-User-Name as response
// headers (after auth). do a HEAD self-fetch to read them, then filter cards.

const userEl = document.getElementById("user");
const emptyEl = document.getElementById("empty");

(async () => {
  let userGroups = [];
  let userName = "";

  try {
    const res = await fetch(location.pathname, { method: "HEAD" });
    userGroups = (res.headers.get("X-User-Groups") || "")
      .split(/\s+/)
      .filter(Boolean);
    userName = res.headers.get("X-User-Name") || "";
  } catch (err) {
    console.warn("self-fetch failed:", err);
  }

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
})();
