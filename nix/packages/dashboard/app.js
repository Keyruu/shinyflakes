// ponytail: PKCE flow → token in sessionStorage → userinfo for group filter.
// forward_auth already gates the page; if we got here, the user is authed
// at auth.peeraten.net and the PKCE dance only fetches a token to read groups.

const userEl = document.getElementById("user");
const emptyEl = document.getElementById("empty");

const CLIENT_ID = "dashboard";
const AUTH_BASE = "https://auth.peeraten.net/api/oidc";
const REDIRECT_URI = location.origin + location.pathname;
const TOKEN_KEY = "dashboard_access_token";
const EXPIRY_KEY = "dashboard_token_expiry";
const VERIFIER_KEY = "dashboard_pkce_verifier";

const base64url = (buf) =>
  btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

const sha256 = (s) =>
  base64url(crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)));

const rand = () => base64url(crypto.getRandomValues(new Uint8Array(32)));

const params = new URLSearchParams(location.search);

(async () => {
  // 1. OIDC callback: exchange code for token
  if (params.has("code")) {
    const verifier = sessionStorage.getItem(VERIFIER_KEY);
    sessionStorage.removeItem(VERIFIER_KEY);
    if (verifier) {
      const res = await fetch(`${AUTH_BASE}/token`, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          code: params.get("code"),
          redirect_uri: REDIRECT_URI,
          client_id: CLIENT_ID,
          code_verifier: verifier,
        }),
      });
      if (res.ok) {
        const data = await res.json();
        sessionStorage.setItem(TOKEN_KEY, data.access_token);
        if (data.expires_in) {
          sessionStorage.setItem(
            EXPIRY_KEY,
            String(Date.now() + data.expires_in * 1000),
          );
        }
        history.replaceState(null, "", REDIRECT_URI);
        location.reload();
        return;
      }
      console.error("token exchange failed:", await res.text());
    }
    return;
  }

  // 2. Need a token? Kick off PKCE authorize flow
  const token = sessionStorage.getItem(TOKEN_KEY);
  const expiry = Number(sessionStorage.getItem(EXPIRY_KEY) || 0);
  if (!token || (expiry && Date.now() >= expiry)) {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(EXPIRY_KEY);
    const verifier = rand();
    sessionStorage.setItem(VERIFIER_KEY, verifier);
    const auth = new URLSearchParams({
      response_type: "code",
      client_id: CLIENT_ID,
      redirect_uri: REDIRECT_URI,
      scope: "openid profile email groups",
      code_challenge: await sha256(verifier),
      code_challenge_method: "S256",
      state: rand(),
    });
    location.href = `${AUTH_BASE}/authorize?${auth}`;
    return;
  }

  // 3. Fetch userinfo, filter cards
  let userGroups = [];
  let userName = "";
  try {
    const res = await fetch(`${AUTH_BASE}/userinfo`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (res.ok) {
      const info = await res.json();
      userGroups = Array.isArray(info.groups) ? info.groups : [];
      userName = info.name || info.email || info.sub || "";
    } else if (res.status === 401) {
      sessionStorage.removeItem(TOKEN_KEY);
      sessionStorage.removeItem(EXPIRY_KEY);
      location.reload();
      return;
    }
  } catch (err) {
    console.warn("userinfo fetch failed:", err);
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
