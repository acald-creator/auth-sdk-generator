import "dotenv/config";
import express from "express";
import { OAuth2Client } from "./sdk/dist/index";

const app = express();
const PORT = 3000;

const CLIENT_ID = process.env.GITHUB_CLIENT_ID!;
const CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET!;

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error("Missing GITHUB_CLIENT_ID or GITHUB_CLIENT_SECRET in .env");
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
      <title>Auth SDK Demo</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 600px; margin: 80px auto; text-align: center; }
        h1 { color: #24292f; }
        p { color: #57606a; margin: 16px 0 32px; }
        a.btn {
          display: inline-block; padding: 12px 24px;
          background: #24292f; color: #fff; text-decoration: none;
          border-radius: 6px; font-weight: 600;
        }
        a.btn:hover { background: #32383f; }
        code { background: #f6f8fa; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
      </style>
    </head>
    <body>
      <h1>Auth SDK Generator Demo</h1>
      <p>This app uses a <strong>generated</strong> TypeScript OAuth2 SDK to authenticate with GitHub.</p>
      <a class="btn" href="/auth">Login with GitHub</a>
    </body>
    </html>
  `);
});

app.get("/auth", async (_req, res) => {
  try {
    const client = new OAuth2Client({
      clientId: CLIENT_ID,
      redirectUri: `http://localhost:${PORT}/callback`,
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
    // Exchange code for tokens
    // GitHub requires client_secret in the token request, so we handle it server-side
    const tokenResponse = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        code,
      }),
    });

    const tokens = await tokenResponse.json() as Record<string, string>;

    if (tokens.error) {
      return res.status(400).send(`GitHub error: ${tokens.error_description || tokens.error}`);
    }

    // Fetch user profile with the access token
    const userResponse = await fetch("https://api.github.com/user", {
      headers: {
        Authorization: `Bearer ${tokens.access_token}`,
        Accept: "application/json",
        "User-Agent": "auth-sdk-demo",
      },
    });

    const user = await userResponse.json() as Record<string, string>;

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Auth SDK Demo - Success</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 600px; margin: 80px auto; }
          h1 { color: #24292f; }
          .card {
            border: 1px solid #d0d7de; border-radius: 8px; padding: 24px;
            margin: 24px 0; background: #f6f8fa;
          }
          .avatar { width: 64px; height: 64px; border-radius: 50%; vertical-align: middle; margin-right: 12px; }
          .user-info { display: flex; align-items: center; margin-bottom: 16px; }
          pre { background: #24292f; color: #e6edf3; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #0969da; }
        </style>
      </head>
      <body>
        <h1>Authenticated!</h1>
        <div class="card">
          <div class="user-info">
            <img class="avatar" src="${user.avatar_url}" alt="avatar" />
            <div>
              <strong>${user.name || user.login}</strong><br/>
              <span style="color: #57606a;">@${user.login}</span>
            </div>
          </div>
          <p>${user.bio || ""}</p>
        </div>

        <h3>Token Response</h3>
        <pre>${JSON.stringify(tokens, null, 2)}</pre>

        <h3>User Profile</h3>
        <pre>${JSON.stringify(user, null, 2)}</pre>

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
  console.log(`\nAuth SDK Demo running at http://localhost:${PORT}\n`);
  console.log("1. Open http://localhost:3000 in your browser");
  console.log('2. Click "Login with GitHub"');
  console.log("3. Authorize the app on GitHub");
  console.log("4. See your profile and tokens\n");
});
