import "dotenv/config";
import express from "express";
import { OAuth2Client } from "../sdk/dist/index.js";

const app = express();
const PORT = 3001;

const CLIENT_ID = process.env.KEYCLOAK_CLIENT_ID || "demo-client";
const CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET!;
const KEYCLOAK_URL = process.env.KEYCLOAK_URL || "http://localhost:8080";
const REALM = process.env.KEYCLOAK_REALM || "demo";
const REALM_URL = `${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect`;

if (!CLIENT_SECRET) {
  console.error("Missing KEYCLOAK_CLIENT_SECRET in .env");
  process.exit(1);
}

// In-memory session store (PoC only)
const sessions = new Map<
  string,
  { client: OAuth2Client; idToken?: string; accessToken?: string }
>();

function createClient(): OAuth2Client {
  return new OAuth2Client({
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    redirectUri: `http://localhost:${PORT}/auth/callback`,
    authorizeUrl: `${REALM_URL}/auth`,
    tokenUrl: `${REALM_URL}/token`,
    introspectUrl: `${REALM_URL}/token/introspect`,
    revokeUrl: `${REALM_URL}/revoke`,
  });
}

// Start OAuth flow — redirect browser to Keycloak's login page
app.get("/auth/login", async (_req, res) => {
  try {
    const client = createClient();
    const authUrl = await client.startAuth();

    const url = new URL(authUrl);
    const state = url.searchParams.get("state")!;
    sessions.set(state, { client });
    setTimeout(() => sessions.delete(state), 10 * 60 * 1000);

    // Keycloak has its own login UI — redirect browser directly
    res.redirect(authUrl);
  } catch (err) {
    console.error("Auth start error:", err);
    res.status(500).json({ error: "Failed to start auth flow" });
  }
});

// Handle OAuth callback — Keycloak redirects here after login
app.get("/auth/callback", async (req, res) => {
  const code = req.query.code as string;
  const state = req.query.state as string;

  if (!code || !state) {
    return res.status(400).json({ error: "Missing code or state" });
  }

  const session = sessions.get(state);
  if (!session) {
    return res.status(400).json({ error: "Unknown state — session expired" });
  }

  try {
    const tokens = await session.client.exchangeCode(code);

    // Keycloak returns id_token when openid scope is requested
    const tokenData = tokens as Record<string, unknown>;
    const idToken = tokenData.id_token as string | undefined;

    if (!idToken) {
      console.error("No id_token. Ensure openid scope is requested.");
      return res.status(500).json({ error: "No id_token received" });
    }

    session.idToken = idToken;
    session.accessToken = tokens.access_token;

    const sessionId = crypto.randomUUID();
    sessions.set(sessionId, session);
    sessions.delete(state);

    // Redirect to frontend with session
    res.redirect(`http://localhost:5173/?session=${sessionId}`);
  } catch (err) {
    console.error("Token exchange error:", err);
    res.status(500).json({ error: "Token exchange failed" });
  }
});

// Frontend fetches the id_token for Convex
app.get("/auth/token", (req, res) => {
  const sessionId = req.query.session as string;
  const session = sessions.get(sessionId);

  if (!session?.idToken) {
    return res.json({ authenticated: false });
  }

  res.json({
    authenticated: true,
    idToken: session.idToken,
    accessToken: session.accessToken,
  });
});

// Logout — revoke token and clear session
app.get("/auth/logout", async (req, res) => {
  const sessionId = req.query.session as string;
  const session = sessions.get(sessionId);

  if (session?.accessToken) {
    try {
      const client = createClient();
      await client.revokeToken(session.accessToken);
    } catch (err) {
      console.error("Revocation error:", err);
    }
  }

  sessions.delete(sessionId);
  res.json({ ok: true });
});

app.listen(PORT, () => {
  console.log(`\nAuth backend running on http://localhost:${PORT}`);
  console.log(`Keycloak: ${KEYCLOAK_URL}`);
  console.log(`Realm: ${REALM}`);
  console.log(`Endpoints: ${REALM_URL}/*\n`);
});
