# Ory Hydra Demo

Multi-service platform auth using a **generated** TypeScript SDK with Ory Hydra.

Demonstrates:
- **Token Introspection** (RFC 7662) - validate tokens from other services
- **Token Revocation** (RFC 7009) - revoke tokens on logout
- **Runtime Config** - Hydra URLs configured from `.env`, not baked into the SDK

## Prerequisites

- Node.js 20+
- The auth-sdk-generator built (`make build` from the repo root)
- Ory Hydra running (see below)

## Hydra Setup

### Quick start with Docker

```bash
# Start Hydra with an in-memory database (for development)
docker run --rm -it \
  -p 4444:4444 \
  -p 4445:4445 \
  -e DSN=memory \
  -e URLS_SELF_ISSUER=http://127.0.0.1:4444 \
  -e URLS_CONSENT=http://localhost:3000/consent \
  -e URLS_LOGIN=http://localhost:3000/login \
  oryd/hydra:v2.2 serve all --dev
```

### Create an OAuth2 client

```bash
# Using the Hydra CLI (or curl to the admin API)
docker exec <container-id> hydra create oauth2-client \
  --endpoint http://127.0.0.1:4445 \
  --grant-type authorization_code,refresh_token \
  --response-type code \
  --scope openid,offline_access,profile,email \
  --redirect-uri http://localhost:3000/callback \
  --token-endpoint-auth-method client_secret_post
```

Copy the client ID and secret from the output.

## Demo Setup

### 1. Generate the SDK

From the repo root:

```bash
./_build/default/bin/main.exe specs/ory-hydra.auth examples/ory-hydra-demo/sdk
```

### 2. Configure credentials

```bash
cd examples/ory-hydra-demo
cp .env.example .env
```

Edit `.env` with the client ID and secret from the Hydra client creation step. Adjust URLs if Hydra is not on localhost.

### 3. Install dependencies and build the SDK

```bash
npm install
npm run build:sdk
```

### 4. Run the demo

```bash
npm start
```

Open [http://localhost:3000](http://localhost:3000) and click **Login via Hydra**.

## Demo Flow

1. **Login** - Redirects to Hydra's authorization endpoint
2. **Callback** - Exchanges the code for tokens (client_secret included automatically)
3. **Introspection** - Validates the token against Hydra's admin introspect endpoint
4. **Revocation** - Click "Revoke Token" to revoke it, then see introspection confirm it's inactive

## Multi-Service Usage

In a real multi-service platform, each service would:

```typescript
import { OAuth2Client } from "@your-org/auth-sdk";

const auth = new OAuth2Client({
  clientId: process.env.SERVICE_CLIENT_ID,
  clientSecret: process.env.SERVICE_CLIENT_SECRET,
  redirectUri: "unused-for-introspection",
  introspectUrl: process.env.HYDRA_ADMIN_URL + "/admin/oauth2/introspect",
});

// Middleware: validate token from incoming request
app.use(async (req, res, next) => {
  const token = req.headers.authorization?.replace("Bearer ", "");
  if (!token) return res.status(401).json({ error: "missing token" });

  const result = await auth.introspectToken(token);
  if (!result.active) return res.status(401).json({ error: "token inactive" });

  req.user = result;
  next();
});
```
