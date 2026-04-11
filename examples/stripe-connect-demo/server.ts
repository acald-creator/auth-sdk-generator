import "dotenv/config";
import express from "express";
import { OAuth2Client } from "./sdk/dist/index";

const app = express();
const PORT = 3000;

const CLIENT_ID = process.env.STRIPE_CLIENT_ID!;
const CLIENT_SECRET = process.env.STRIPE_CLIENT_SECRET!;

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error("Missing STRIPE_CLIENT_ID or STRIPE_CLIENT_SECRET in .env");
  process.exit(1);
}

// Store OAuth clients keyed by state to preserve PKCE verifier across requests
const pendingAuths = new Map<string, OAuth2Client>();

// --- Routes ---

app.get("/", (_req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Stripe Connect Demo</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
        h1 { color: #635bff; }
        p { color: #57606a; line-height: 1.6; }
        a.btn {
          display: inline-block; padding: 12px 24px;
          background: #635bff; color: #fff; text-decoration: none;
          border-radius: 6px; font-weight: 600;
        }
        a.btn:hover { background: #7a73ff; }
        .features { margin: 32px 0; }
        .feature { padding: 12px 0; border-bottom: 1px solid #e5e7eb; }
        .feature:last-child { border-bottom: none; }
        .tag { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 600; margin-right: 8px; }
        .tag-secret { background: #fef3c7; color: #92400e; }
        .tag-runtime { background: #dbeafe; color: #1e40af; }
        .tag-lifecycle { background: #d1fae5; color: #065f46; }
      </style>
    </head>
    <body>
      <h1>Stripe Connect Demo</h1>
      <p>This app uses a <strong>generated</strong> TypeScript OAuth2 SDK to connect Stripe accounts.
         The SDK was generated from a 7-line <code>.auth</code> spec file.</p>

      <div class="features">
        <div class="feature">
          <span class="tag tag-secret">#19</span>
          <strong>Client Secret</strong> &mdash; <code>client_secret</code> is sent automatically in token exchanges
        </div>
        <div class="feature">
          <span class="tag tag-runtime">#17</span>
          <strong>Runtime Config</strong> &mdash; endpoint URLs can be overridden per-environment (test/live)
        </div>
        <div class="feature">
          <span class="tag tag-lifecycle">#18</span>
          <strong>Token Lifecycle</strong> &mdash; <code>getAccessToken()</code> auto-refreshes expired tokens
        </div>
      </div>

      <a class="btn" href="/auth">Connect with Stripe</a>
    </body>
    </html>
  `);
});

app.get("/auth", async (_req, res) => {
  try {
    // Feature #19: clientSecret flows through to token exchange automatically
    // Feature #17: URLs could be overridden here for test vs live Stripe environments
    const client = new OAuth2Client({
      clientId: CLIENT_ID,
      clientSecret: CLIENT_SECRET,
      redirectUri: `http://localhost:${PORT}/callback`,
    });

    const authUrl = await client.startAuth();

    // Extract state to look up the client on callback
    const url = new URL(authUrl);
    const state = url.searchParams.get("state")!;
    pendingAuths.set(state, client);
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
    return res.status(400).send("Unknown state parameter - session expired or invalid");
  }
  pendingAuths.delete(state);

  try {
    // Feature #19: exchangeCode now includes client_secret automatically
    const tokens = await client.exchangeCode(code);

    // Feature #18: getAccessToken() returns cached token or auto-refreshes
    const accessToken = await client.getAccessToken();

    // Use the token to fetch connected account details
    const accountRes = await fetch("https://api.stripe.com/v1/account", {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: "application/json",
      },
    });
    const account = await accountRes.json() as Record<string, unknown>;

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Stripe Connect Demo - Connected</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 700px; margin: 80px auto; }
          h1 { color: #635bff; }
          .card {
            border: 1px solid #e5e7eb; border-radius: 8px; padding: 24px;
            margin: 24px 0; background: #f9fafb;
          }
          pre { background: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 0.85em; }
          a { color: #635bff; }
          .success { color: #065f46; font-weight: 600; }
        </style>
      </head>
      <body>
        <h1>Connected!</h1>
        <p class="success">Stripe account connected successfully via the generated SDK.</p>

        <div class="card">
          <strong>Account ID:</strong> ${account.id || "N/A"}<br/>
          <strong>Business:</strong> ${(account.business_profile as Record<string, unknown>)?.name || account.email || "N/A"}<br/>
          <strong>Country:</strong> ${account.country || "N/A"}
        </div>

        <h3>Token Response</h3>
        <pre>${JSON.stringify(tokens, null, 2)}</pre>

        <h3>Account Details</h3>
        <pre>${JSON.stringify(account, null, 2)}</pre>

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
  console.log(`\nStripe Connect Demo running at http://localhost:${PORT}\n`);
  console.log("Features demonstrated:");
  console.log("  #17 Runtime Config   - endpoint URLs overridable at runtime");
  console.log("  #18 Token Lifecycle  - getAccessToken() with auto-refresh");
  console.log("  #19 Client Secret    - client_secret sent in token exchange\n");
});
