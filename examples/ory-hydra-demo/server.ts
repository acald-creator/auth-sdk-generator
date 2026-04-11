import "dotenv/config";
import express from "express";
import { OAuth2Client } from "./sdk/dist/index";

const app = express();
const PORT = 3000;

const CLIENT_ID = process.env.HYDRA_CLIENT_ID!;
const CLIENT_SECRET = process.env.HYDRA_CLIENT_SECRET!;
const HYDRA_PUBLIC = process.env.HYDRA_PUBLIC_URL || "http://127.0.0.1:4444";
const HYDRA_ADMIN = process.env.HYDRA_ADMIN_URL || "http://127.0.0.1:4445";

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error("Missing HYDRA_CLIENT_ID or HYDRA_CLIENT_SECRET in .env");
  process.exit(1);
}

// Store OAuth clients keyed by state to preserve PKCE verifier
const pendingAuths = new Map<string, OAuth2Client>();

// Helper: create a client with runtime URL overrides from env
function createClient(): OAuth2Client {
  return new OAuth2Client({
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    redirectUri: `http://localhost:${PORT}/callback`,
    // Runtime config: override endpoints from environment
    authorizeUrl: `${HYDRA_PUBLIC}/oauth2/auth`,
    tokenUrl: `${HYDRA_PUBLIC}/oauth2/token`,
    introspectUrl: `${HYDRA_ADMIN}/admin/oauth2/introspect`,
    revokeUrl: `${HYDRA_PUBLIC}/oauth2/revoke`,
  });
}

// --- Routes ---

app.get("/", (_req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Ory Hydra Demo</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
        h1 { color: #1a1a2e; }
        p { color: #57606a; line-height: 1.6; }
        .actions { display: flex; gap: 12px; margin: 32px 0; }
        a.btn {
          display: inline-block; padding: 12px 24px;
          color: #fff; text-decoration: none;
          border-radius: 6px; font-weight: 600;
        }
        .btn-primary { background: #1a1a2e; }
        .btn-primary:hover { background: #2d2d44; }
        .features { margin: 32px 0; }
        .feature { padding: 12px 0; border-bottom: 1px solid #e5e7eb; }
        .feature:last-child { border-bottom: none; }
        .tag { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 600; margin-right: 8px; }
        .tag-introspect { background: #ede9fe; color: #5b21b6; }
        .tag-revoke { background: #fce7f3; color: #9d174d; }
        .tag-runtime { background: #dbeafe; color: #1e40af; }
        code { background: #f6f8fa; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
      </style>
    </head>
    <body>
      <h1>Ory Hydra Demo</h1>
      <p>Multi-service platform auth using a <strong>generated</strong> TypeScript OAuth2 SDK
         with Ory Hydra. Built for validating tokens across services.</p>

      <div class="features">
        <div class="feature">
          <span class="tag tag-introspect">RFC 7662</span>
          <strong>Token Introspection</strong> &mdash; validate tokens from other services via <code>introspectToken()</code>
        </div>
        <div class="feature">
          <span class="tag tag-revoke">RFC 7009</span>
          <strong>Token Revocation</strong> &mdash; revoke tokens on logout via <code>revokeToken()</code>
        </div>
        <div class="feature">
          <span class="tag tag-runtime">Runtime</span>
          <strong>Environment Config</strong> &mdash; Hydra URLs configured from <code>.env</code>, not baked in
        </div>
      </div>

      <div class="actions">
        <a class="btn btn-primary" href="/auth">Login via Hydra</a>
      </div>

      <p style="font-size: 0.85em; color: #9ca3af;">
        Hydra public: <code>${HYDRA_PUBLIC}</code><br/>
        Hydra admin: <code>${HYDRA_ADMIN}</code>
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
    res.status(500).send("Failed to start OAuth flow. Is Hydra running?");
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

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Ory Hydra Demo - Authenticated</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
          h1 { color: #1a1a2e; }
          h3 { margin-top: 24px; }
          .card {
            border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px;
            margin: 16px 0; background: #f9fafb;
          }
          .active { border-color: #22c55e; background: #f0fdf4; }
          .revoked { border-color: #ef4444; background: #fef2f2; }
          pre { background: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #5b21b6; }
          .actions { display: flex; gap: 12px; margin: 24px 0; }
          a.btn {
            display: inline-block; padding: 10px 20px;
            color: #fff; text-decoration: none;
            border-radius: 6px; font-weight: 600; font-size: 0.9em;
          }
          .btn-revoke { background: #ef4444; }
          .btn-revoke:hover { background: #dc2626; }
          .btn-home { background: #6b7280; }
          .btn-home:hover { background: #4b5563; }
        </style>
      </head>
      <body>
        <h1>Authenticated!</h1>

        <h3>Token Introspection (RFC 7662)</h3>
        <div class="card ${introspection.active ? "active" : "revoked"}">
          <strong>Active:</strong> ${introspection.active ? "Yes" : "No"}<br/>
          <strong>Subject:</strong> ${introspection.sub || "N/A"}<br/>
          <strong>Scopes:</strong> ${introspection.scope || "N/A"}<br/>
          <strong>Client ID:</strong> ${introspection.client_id || "N/A"}
        </div>

        <div class="actions">
          <a class="btn btn-revoke" href="/revoke?token=${encodeURIComponent(tokens.access_token)}">
            Revoke Token
          </a>
          <a class="btn btn-home" href="/">Start Over</a>
        </div>

        <h3>Token Response</h3>
        <pre>${JSON.stringify(tokens, null, 2)}</pre>

        <h3>Full Introspection Response</h3>
        <pre>${JSON.stringify(introspection, null, 2)}</pre>
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
  if (!token) {
    return res.status(400).send("Missing token parameter");
  }

  try {
    const client = createClient();

    // Revoke the token
    await client.revokeToken(token);

    // Introspect again to confirm it's revoked
    const introspection = await client.introspectToken(token);

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Ory Hydra Demo - Token Revoked</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
          h1 { color: #ef4444; }
          .card { border: 1px solid #ef4444; border-radius: 8px; padding: 16px; margin: 16px 0; background: #fef2f2; }
          pre { background: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #5b21b6; }
        </style>
      </head>
      <body>
        <h1>Token Revoked</h1>

        <div class="card">
          <strong>Active:</strong> ${introspection.active ? "Yes (unexpected)" : "No (confirmed revoked)"}<br/>
          <p>The token has been revoked via Hydra's revocation endpoint (RFC 7009).</p>
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
  console.log(`\nOry Hydra Demo running at http://localhost:${PORT}\n`);
  console.log(`Hydra Public: ${HYDRA_PUBLIC}`);
  console.log(`Hydra Admin:  ${HYDRA_ADMIN}\n`);
  console.log("Features demonstrated:");
  console.log("  - Token Introspection (RFC 7662)");
  console.log("  - Token Revocation (RFC 7009)");
  console.log("  - Runtime endpoint configuration\n");
});
