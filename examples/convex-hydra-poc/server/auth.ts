import "dotenv/config";
import express from "express";
import { OAuth2Client } from "../sdk/dist/index.js";

const app = express();
const PORT = 3001;

const CLIENT_ID = process.env.HYDRA_CLIENT_ID || "convex-hydra-poc";
const CLIENT_SECRET = process.env.HYDRA_CLIENT_SECRET || "poc-secret";
const HYDRA_PUBLIC = process.env.HYDRA_PUBLIC_URL || "http://127.0.0.1:4444";
const HYDRA_ADMIN = process.env.HYDRA_ADMIN_URL || "http://127.0.0.1:4445";
const ISSUER_URL = process.env.HYDRA_ISSUER_URL || HYDRA_PUBLIC;

// In-memory session store (PoC only)
const sessions = new Map<
  string,
  { idToken?: string; accessToken?: string }
>();

function createClient(): OAuth2Client {
  return new OAuth2Client({
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    redirectUri: `http://localhost:3001/auth/internal/callback`,
    authorizeUrl: `${HYDRA_PUBLIC}/oauth2/auth`,
    tokenUrl: `${HYDRA_PUBLIC}/oauth2/token`,
    introspectUrl: `${HYDRA_ADMIN}/admin/oauth2/introspect`,
    revokeUrl: `${HYDRA_PUBLIC}/oauth2/revoke`,
  });
}

// Helper: follow a redirect chain server-side, handling Hydra login + consent
async function followHydraFlow(initialUrl: string): Promise<string> {
  let url = initialUrl;
  const cookieJar: string[] = [];

  for (let i = 0; i < 15; i++) {
    const res = await fetch(url, {
      redirect: "manual",
      headers: cookieJar.length > 0 ? { Cookie: cookieJar.join("; ") } : {},
    });

    // Collect cookies
    const setCookies = res.headers.getSetCookie?.() || [];
    for (const c of setCookies) {
      cookieJar.push(c.split(";")[0]);
    }

    const location = res.headers.get("location");
    if (!location) {
      throw new Error(`No redirect at step ${i}, status ${res.status}`);
    }

    const nextUrl = new URL(location, url).toString();

    // If it's a login challenge → accept it server-side
    if (nextUrl.includes("/auth/hydra/login") || nextUrl.includes("login_challenge=")) {
      const challenge = new URL(nextUrl).searchParams.get("login_challenge")!;
      const acceptRes = await fetch(
        `${HYDRA_ADMIN}/admin/oauth2/auth/requests/login/accept?login_challenge=${challenge}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            subject: "poc-user",
            remember: true,
            remember_for: 3600,
          }),
        },
      );
      const body = (await acceptRes.json()) as Record<string, string>;
      url = body.redirect_to;
      continue;
    }

    // If it's a consent challenge → accept it server-side
    if (nextUrl.includes("/auth/hydra/consent") || nextUrl.includes("consent_challenge=")) {
      const challenge = new URL(nextUrl).searchParams.get("consent_challenge")!;

      const consentRes = await fetch(
        `${HYDRA_ADMIN}/admin/oauth2/auth/requests/consent?consent_challenge=${challenge}`,
      );
      const consentReq = (await consentRes.json()) as Record<string, unknown>;

      const acceptRes = await fetch(
        `${HYDRA_ADMIN}/admin/oauth2/auth/requests/consent/accept?consent_challenge=${challenge}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            grant_scope: consentReq.requested_scope,
            grant_access_token_audience: consentReq.requested_access_token_audience,
            remember: true,
            remember_for: 3600,
            session: {
              id_token: {
                name: "PoC User",
                email: "poc@example.com",
              },
            },
          }),
        },
      );
      const body = (await acceptRes.json()) as Record<string, string>;
      url = body.redirect_to;
      continue;
    }

    // If it redirects to our callback with a code → we're done
    if (nextUrl.includes("/auth/internal/callback") && nextUrl.includes("code=")) {
      return nextUrl;
    }

    // Otherwise, follow the redirect
    url = nextUrl;
  }

  throw new Error("Too many redirects in Hydra flow");
}

// --- Routes ---

// Start and complete the entire OAuth flow server-side.
// The browser never talks to Hydra directly (fixes WSL2 port forwarding issues).
app.get("/auth/login", async (_req, res) => {
  try {
    const client = createClient();
    const authUrl = await client.startAuth();

    // Follow the entire Hydra flow server-side
    const callbackUrl = await followHydraFlow(authUrl);

    // Extract the code from the callback URL
    const url = new URL(callbackUrl);
    const code = url.searchParams.get("code")!;

    // Exchange code for tokens
    const tokens = await client.exchangeCode(code);

    // Extract id_token
    const tokenData = tokens as Record<string, unknown>;
    const idToken = tokenData.id_token as string | undefined;

    if (!idToken) {
      console.error("No id_token in response. Ensure openid scope is requested.");
      return res.status(500).json({ error: "No id_token received from Hydra" });
    }

    // Store in session
    const sessionId = crypto.randomUUID();
    sessions.set(sessionId, {
      idToken,
      accessToken: tokens.access_token,
    });
    setTimeout(() => sessions.delete(sessionId), 60 * 60 * 1000);

    // Redirect browser to frontend with session
    res.redirect(`/?session=${sessionId}`);
  } catch (err) {
    console.error("Auth flow error:", err);
    res.status(500).send(`Auth flow failed: ${err}`);
  }
});

// Internal callback — only used as the redirect_uri for Hydra (never hit by browser)
app.get("/auth/internal/callback", (_req, res) => {
  res.send("This endpoint is only used internally.");
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

// Debug endpoint — shows JWT claims, JWKS reachability, and auth config
app.get("/auth/debug", async (req, res) => {
  const sessionId = req.query.session as string;
  const session = sessions.get(sessionId);

  const debug: Record<string, unknown> = {
    hydra_public: HYDRA_PUBLIC,
    hydra_admin: HYDRA_ADMIN,
    issuer_url: ISSUER_URL,
    has_session: !!session,
    has_id_token: !!session?.idToken,
  };

  // Decode JWT
  if (session?.idToken) {
    try {
      const parts = session.idToken.split(".");
      const header = JSON.parse(Buffer.from(parts[0], "base64url").toString());
      const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString());
      debug.jwt_header = header;
      debug.jwt_payload = payload;
    } catch (e) {
      debug.jwt_decode_error = String(e);
    }
  }

  // Test JWKS reachability
  try {
    const jwksUrl = `${ISSUER_URL}/.well-known/jwks.json`;
    debug.jwks_url = jwksUrl;
    const jwksRes = await fetch(jwksUrl);
    debug.jwks_status = jwksRes.status;
    const jwks = await jwksRes.json() as Record<string, unknown>;
    debug.jwks_key_count = (jwks.keys as unknown[])?.length;
  } catch (e) {
    debug.jwks_error = String(e);
  }

  // Test OIDC discovery
  try {
    const oidcUrl = `${ISSUER_URL}/.well-known/openid-configuration`;
    const oidcRes = await fetch(oidcUrl);
    const oidc = await oidcRes.json() as Record<string, unknown>;
    debug.oidc_issuer = oidc.issuer;
    debug.oidc_jwks_uri = oidc.jwks_uri;
  } catch (e) {
    debug.oidc_error = String(e);
  }

  // Convex config comparison
  debug.convex_config = {
    expected_issuer: ISSUER_URL,
    expected_application_id: "convex-hydra-poc",
    note: "JWT iss must match convex issuer, JWT aud must contain applicationID",
  };

  res.json(debug);
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
  console.log(`Hydra: ${HYDRA_PUBLIC}`);
  console.log(`Issuer: ${ISSUER_URL}`);
  console.log(`\nThe browser never contacts Hydra directly — all OAuth flow is server-side.\n`);
});
