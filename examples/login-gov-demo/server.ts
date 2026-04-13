import "dotenv/config";
import express from "express";
import { OAuth2Client } from "./sdk/src/index";

const app = express();
const PORT = 3001;

const CLIENT_ID = process.env.LOGINGOV_CLIENT_ID!;

if (!CLIENT_ID) {
  console.error("Missing LOGINGOV_CLIENT_ID in .env");
  process.exit(1);
}

// Store OAuth clients keyed by state parameter to preserve PKCE verifier across requests
const pendingAuths = new Map<string, OAuth2Client>();

// --- Routes ---

app.get("/", (_req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Login.gov SDK Demo</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 600px; margin: 80px auto; text-align: center; }
        h1 { color: #003366; }
        p { color: #57606a; margin: 16px 0 32px; }
        a.btn {
          display: inline-block; padding: 12px 24px;
          background: #003366; color: #fff; text-decoration: none;
          border-radius: 6px; font-weight: 600;
        }
        a.btn:hover { background: #004080; }
        code { background: #f6f8fa; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
      </style>
    </head>
    <body>
      <h1>Login.gov Sandbox Demo</h1>
      <p>This app uses a <strong>generated</strong> TypeScript OAuth2 SDK with PKCE to authenticate with Login.gov Sandbox.</p>
      <a class="btn" href="/auth">Login with Login.gov</a>
    </body>
    </html>
  `);
});

app.get("/auth", async (_req, res) => {
  try {
    const client = new OAuth2Client({
      clientId: CLIENT_ID,
      redirectUri: `http://localhost:${PORT}/callback`,
      scopes: ["openid", "email"]
    });

    const authUrl = await client.startAuth();

    // Extract state from the generated URL so we can look up the client later
    const url = new URL(authUrl);
    const state = url.searchParams.get("state")!;
    pendingAuths.set(state, client);

    // Clean up stale entries after 10 minutes
    setTimeout(() => pendingAuths.delete(state), 10 * 60 * 1000);

    res.redirect(authUrl);
  } catch (err) {
    console.error("Auth start error:", err);
    res.status(500).send("Failed to start OAuth flow");
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
    return res.status(400).send("Unknown state parameter — session expired or invalid");
  }
  pendingAuths.delete(state);

  try {
    // Exchange code for tokens (using the PKCE verifier stored inside the client)
    const tokens = await client.exchangeCode(code);

    // Login.gov tokens are typically JWTs
    // For this demo, we'll just show the tokens
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Login.gov SDK Demo - Success</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 600px; margin: 80px auto; }
          h1 { color: #003366; }
          pre { background: #f6f8fa; border: 1px solid #d0d7de; color: #24292f; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #003366; }
        </style>
      </head>
      <body>
        <h1>Authenticated with Login.gov!</h1>
        <p>Successfully exchanged the authorization code for tokens using PKCE.</p>

        <h3>Token Response</h3>
        <pre>${JSON.stringify(tokens, null, 2)}</pre>

        <p><a href="/">Start over</a></p>
      </body>
      </html>
    `);
  } catch (err) {
    console.error("Token exchange error:", err);
    res.status(500).send("Failed to exchange code for tokens");
  }
});

app.listen(PORT, () => {
  console.log(`\nLogin.gov SDK Demo running at http://localhost:${PORT}\n`);
  console.log("1. Open http://localhost:3001 in your browser");
  console.log('2. Click "Login with Login.gov"');
  console.log("3. Authorize the app on Login.gov Sandbox");
  console.log("4. See your tokens\n");
});
