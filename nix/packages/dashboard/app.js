// ponytail: single CORS fetch to userinfo + per-card group match.
// authelia's forward_auth already gated the page; if we got here, the user is authed.

const userEl = document.getElementById("user");
const emptyEl = document.getElementById("empty");

(async () => {
  let userGroups = [];
  let userName = "";

  try {
    const res = await fetch("https://auth.peeraten.net/api/oidc/userinfo", {
      credentials: "include",
    });
    if (res.ok) {
      const info = await res.json();
      userGroups = Array.isArray(info.groups) ? info.groups : [];
      userName = info.name || info.email || info.sub || "";
    }
  } catch (err) {
    console.warn("userinfo fetch failed:", err);
  }

  if (userName) userEl.textContent = `Signed in as ${userName}`;

  let visible = 0;
  document.querySelectorAll(".card").forEach((card) => {
    const required = (card.dataset.groups || "").split(/\s+/).filter(Boolean);
    // empty groups = visible to all authed users
    const allowed = required.length === 0 || required.some((g) => userGroups.includes(g));
    if (allowed) visible++;
    else card.hidden = true;
  });

  if (visible === 0) emptyEl.hidden = false;
})();
