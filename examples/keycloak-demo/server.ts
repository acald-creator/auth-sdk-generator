import "dotenv/config";
import express from "express";
import { OAuth2Client } from "./sdk/dist/index.js";

const app = express();
const PORT = 3000;

const CLIENT_ID = process.env.KEYCLOAK_CLIENT_ID || "demo-client";
const CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET || "demo-secret";
const KEYCLOAK_URL = process.env.KEYCLOAK_URL || "http://localhost:8080";
const REALM = process.env.KEYCLOAK_REALM || "demo";
const REALM_URL = `${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect`;

// Store OAuth clients keyed by state to preserve PKCE verifier
const pendingAuths = new Map<string, OAuth2Client>();

function createClient(): OAuth2Client {
  return new OAuth2Client({
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    redirectUri: `http://localhost:${PORT}/callback`,
    // Runtime config: endpoints built from realm URL
    authorizeUrl: `${REALM_URL}/auth`,
    tokenUrl: `${REALM_URL}/token`,
    introspectUrl: `${REALM_URL}/token/introspect`,
    revokeUrl: `${REALM_URL}/revoke`,
  });
}

// --- Routes ---

app.get("/", (_req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Keycloak Demo</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
        h1 { color: #4e73df; }
        p { color: #57606a; line-height: 1.6; }
        .actions { display: flex; gap: 12px; margin: 32px 0; }
        a.btn {
          display: inline-block; padding: 12px 24px;
          color: #fff; text-decoration: none;
          border-radius: 6px; font-weight: 600;
        }
        .btn-primary { background: #4e73df; }
        .btn-primary:hover { background: #3a5bc7; }
        .features { margin: 32px 0; }
        .feature { padding: 12px 0; border-bottom: 1px solid #e5e7eb; }
        .feature:last-child { border-bottom: none; }
        .tag { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 600; margin-right: 8px; }
        .tag-oidc { background: #dbeafe; color: #1e40af; }
        .tag-introspect { background: #ede9fe; color: #5b21b6; }
        .tag-revoke { background: #fce7f3; color: #9d174d; }
        code { background: #f6f8fa; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
      </style>
    </head>
    <body>
      <h1>Keycloak Demo</h1>
      <p>Enterprise OAuth using a <strong>generated</strong> TypeScript SDK with Keycloak.
         Keycloak provides its own login UI &mdash; no consent app needed.</p>

      <div class="features">
        <div class="feature">
          <span class="tag tag-oidc">OIDC</span>
          <strong>Full OIDC</strong> &mdash; Keycloak issues <code>id_token</code> with user claims
        </div>
        <div class="feature">
          <span class="tag tag-introspect">RFC 7662</span>
          <strong>Token Introspection</strong> &mdash; validate tokens via <code>introspectToken()</code>
        </div>
        <div class="feature">
          <span class="tag tag-revoke">RFC 7009</span>
          <strong>Token Revocation</strong> &mdash; revoke tokens via <code>revokeToken()</code>
        </div>
      </div>

      <div class="actions">
        <a class="btn btn-primary" href="/auth">Login with Keycloak</a>
      </div>

      <p style="font-size: 0.85em; color: #9ca3af;">
        Keycloak: <code>${KEYCLOAK_URL}</code><br/>
        Realm: <code>${REALM}</code>
      </p>
    </body>
    </html>
  `);
});

app.get("/auth", async (_req, res) => {
  try {
    const client = createClient();
    const authUrl = await client.startAuth();

    const url = new URL(authUrl);
    const state = url.searchParams.get("state")!;
    pendingAuths.set(state, client);
    setTimeout(() => pendingAuths.delete(state), 10 * 60 * 1000);

    res.redirect(authUrl);
  } catch (err) {
    console.error("Auth start error:", err);
    res.status(500).send("Failed to start OAuth flow. Is Keycloak running?");
  }
});

app.get("/callback", async (req, res) => {
  const code = req.query.code as string;
  const state = req.query.state as string;

  if (!code) {
    return res.status(400).send("Missing authorization code");
  }

  const client = pendingAuths.get(state);
  if (!client) {
    return res.status(400).send("Unknown state parameter - session expired or invalid");
  }
  pendingAuths.delete(state);

  try {
    // Exchange code for tokens (client_secret included automatically)
    const tokens = await client.exchangeCode(code);

    // Introspect the token to verify it's active
    const introspection = await client.introspectToken(tokens.access_token);

    // Get user info from the token endpoint's id_token or userinfo
    const userinfoRes = await fetch(`${REALM_URL}/userinfo`, {
      headers: { Authorization: `Bearer ${tokens.access_token}` },
    });
    const userinfo = await userinfoRes.json() as Record<string, string>;

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Keycloak Demo - Authenticated</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
          h1 { color: #4e73df; }
          h3 { margin-top: 24px; }
          .card {
            border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px;
            margin: 16px 0; background: #f9fafb;
          }
          .active { border-color: #22c55e; background: #f0fdf4; }
          .revoked { border-color: #ef4444; background: #fef2f2; }
          pre { background: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #4e73df; }
          .actions { display: flex; gap: 12px; margin: 24px 0; }
          a.btn {
            display: inline-block; padding: 10px 20px;
            color: #fff; text-decoration: none;
            border-radius: 6px; font-weight: 600; font-size: 0.9em;
          }
          .btn-revoke { background: #ef4444; }
          .btn-home { background: #6b7280; }
        </style>
      </head>
      <body>
        <h1>Authenticated!</h1>

        <div class="card active">
          <strong>Username:</strong> ${userinfo.preferred_username || userinfo.sub}<br/>
          <strong>Name:</strong> ${userinfo.name || "N/A"}<br/>
          <strong>Email:</strong> ${userinfo.email || "N/A"}<br/>
          <strong>Active:</strong> ${introspection.active ? "Yes" : "No"}
        </div>

        <div class="actions">
          <a class="btn btn-revoke" href="/revoke?token=${encodeURIComponent(tokens.access_token)}">
            Revoke Token
          </a>
          <a class="btn btn-home" href="/">Start Over</a>
        </div>

        <h3>Token Introspection</h3>
        <pre>${JSON.stringify(introspection, null, 2)}</pre>

        <h3>User Info</h3>
        <pre>${JSON.stringify(userinfo, null, 2)}</pre>

        <h3>Token Response</h3>
        <pre>${JSON.stringify(tokens, null, 2)}</pre>
      </body>
      </html>
    `);
  } catch (err) {
    console.error("Token exchange error:", err);
    res.status(500).send("Failed to exchange code for tokens");
  }
});

app.get("/revoke", async (req, res) => {
  const token = req.query.token as string;
  if (!token) return res.status(400).send("Missing token");

  try {
    const client = createClient();
    await client.revokeToken(token);
    const introspection = await client.introspectToken(token);

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Keycloak Demo - Token Revoked</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
          h1 { color: #ef4444; }
          .card { border: 1px solid #ef4444; border-radius: 8px; padding: 16px; margin: 16px 0; background: #fef2f2; }
          pre { background: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #4e73df; }
        </style>
      </head>
      <body>
        <h1>Token Revoked</h1>
        <div class="card">
          <strong>Active:</strong> ${introspection.active ? "Yes (unexpected)" : "No (confirmed revoked)"}
        </div>
        <h3>Post-Revocation Introspection</h3>
        <pre>${JSON.stringify(introspection, null, 2)}</pre>
        <p><a href="/">Login again</a></p>
      </body>
      </html>
    `);
  } catch (err) {
    console.error("Revocation error:", err);
    res.status(500).send("Failed to revoke token");
  }
});

app.listen(PORT, () => {
  console.log(`\nKeycloak Demo running at http://localhost:${PORT}\n`);
  console.log(`Keycloak: ${KEYCLOAK_URL}`);
  console.log(`Realm: ${REALM}`);
  console.log(`Endpoints: ${REALM_URL}/*\n`);
});
