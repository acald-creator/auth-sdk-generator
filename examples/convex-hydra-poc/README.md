# Convex + Ory Hydra PoC

Full-stack PoC using a **generated** OAuth2 SDK to authenticate with Ory Hydra and pass identity to Convex via custom OIDC auth.

**Stack:** React (Vite) + Convex + Ory Hydra + Generated TypeScript SDK

## How It Works

1. User clicks "Login" in the React app
2. Express backend starts OAuth flow using the generated SDK (`startAuth()`)
3. User authenticates on Hydra, gets redirected back with an authorization code
4. Backend exchanges code for tokens via the generated SDK (`exchangeCode()`)
5. The `id_token` (JWT) is passed to the React app
6. React passes the `id_token` to Convex via `ConvexProviderWithAuth`
7. Convex validates the JWT against Hydra's JWKS endpoint
8. Authenticated queries return the user's identity

## Prerequisites

- Node.js 20+
- Docker (for Hydra)
- ngrok (to expose Hydra to Convex Cloud)
- Convex account (`npx convex login`)
- The auth-sdk-generator built (`make build` from repo root)

## Setup

### 1. Start Hydra with ngrok

Start Hydra:

```bash
docker run --rm -d \
  --name hydra \
  -p 4444:4444 \
  -p 4445:4445 \
  -e DSN=memory \
  -e SECRETS_SYSTEM=a-very-secret-key-that-is-at-least-32-chars \
  -e URLS_SELF_ISSUER=https://YOUR-NGROK-ID.ngrok-free.app \
  -e URLS_CONSENT=http://localhost:5173/auth/callback \
  -e URLS_LOGIN=http://localhost:5173/auth/callback \
  docker.io/oryd/hydra:v2.2 serve all --dev
```

Expose Hydra's public port via ngrok:

```bash
ngrok http 4444
```

Copy the ngrok URL (e.g., `https://abc123.ngrok-free.app`). You'll need to restart Hydra with this URL as `URLS_SELF_ISSUER`.

### 2. Create an OAuth2 client

```bash
curl -s -X POST http://127.0.0.1:4445/admin/clients \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "convex-hydra-poc",
    "client_secret": "poc-secret",
    "grant_types": ["authorization_code", "refresh_token"],
    "response_types": ["code"],
    "scope": "openid offline_access profile email",
    "redirect_uris": ["http://localhost:5173/auth/callback"],
    "audience": ["convex-hydra-poc"],
    "token_endpoint_auth_method": "client_secret_post"
  }'
```

### 3. Generate the SDK

From the repo root:

```bash
./_build/default/bin/main.exe specs/ory-hydra.auth examples/convex-hydra-poc/sdk
```

### 4. Configure

```bash
cd examples/convex-hydra-poc
cp .env.example .env
```

Edit `.env`:
- Set `HYDRA_ISSUER_URL` to your ngrok URL
- Set client credentials if you changed them

### 5. Install dependencies

```bash
npm install
npm run build:sdk
```

### 6. Set up Convex

```bash
npx convex dev
```

This will create the deployment and generate the Convex client code. Update `convex/auth.config.ts` with your ngrok URL as the `domain`.

### 7. Run the app

In a separate terminal:

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) and click **Login with Hydra**.

## Architecture

```
Browser (React + Convex Client)
  ├── /auth/login ──→ Express backend ──→ Hydra authorize
  ├── /auth/callback ←── Hydra ──→ Express exchangeCode()
  ├── id_token ──→ ConvexProviderWithAuth
  └── Convex query (whoami) ──→ Convex Cloud validates JWT via JWKS

Express Backend (port 3001)
  └── Uses generated SDK: startAuth(), exchangeCode(), revokeToken()

Convex Cloud
  └── Validates id_token against Hydra's /.well-known/jwks.json (via ngrok)

Ory Hydra (port 4444/4445, exposed via ngrok)
  └── Issues OAuth2 + OIDC tokens
```
