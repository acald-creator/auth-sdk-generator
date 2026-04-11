# Convex + Keycloak PoC

Full-stack PoC using a **generated** OAuth2 SDK to authenticate with Keycloak and pass identity to Convex.

**Stack:** React (Vite) + Convex + Keycloak + Generated TypeScript SDK

Unlike the Hydra PoC, Keycloak provides its own login UI — the browser redirects directly to Keycloak's login page.

## Prerequisites

- Node.js 20+
- Docker (for Keycloak)
- ngrok (to expose Keycloak to Convex Cloud)
- Convex account (`npx convex login`)
- The auth-sdk-generator built (`make build` from repo root)

## Setup

### 1. Start Keycloak

```bash
docker run --rm -d \
  --name keycloak \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  docker.io/keycloak/keycloak:26.0 start-dev
```

Wait ~30 seconds, then open http://localhost:8080/admin (login: `admin` / `admin`).

### 2. Configure Keycloak

**Create realm:** Top-left dropdown → **Create realm** → Name: `demo` → Create

**Create client:**
1. **Clients** → **Create client** → Client ID: `demo-client` → **Next**
2. Enable **Client authentication** → **Next**
3. Valid redirect URIs: `http://localhost:3001/auth/callback` → **Save**
4. **Credentials** tab → copy **Client secret**

**Create test user:**
1. **Users** → **Add user** → Username: `testuser`, Email: `test@example.com`, First: `Test`, Last: `User` → **Create**
2. **Credentials** tab → **Set password** → `password` → disable Temporary → **Save**

### 3. Expose Keycloak via ngrok

```bash
ngrok http 8080
```

Copy the ngrok URL (e.g., `https://abc123.ngrok-free.app`).

### 4. Generate the SDK

```bash
# From repo root
./_build/default/bin/main.exe specs/keycloak.auth examples/convex-keycloak-poc/sdk
```

### 5. Configure

```bash
cd examples/convex-keycloak-poc
cp .env.example .env
```

Edit `.env` with client secret and ngrok URL.

Update `convex/auth.config.ts` with your ngrok URL:
```typescript
const KEYCLOAK_ISSUER = "https://YOUR-NGROK-ID.ngrok-free.app/realms/demo";
```

### 6. Install and initialize

```bash
npm install
npm run build:sdk
npx convex dev --once   # Initialize Convex
```

### 7. Run

In separate terminals:

```bash
# Terminal 1: Convex
npx convex dev

# Terminal 2: App (starts Vite + Express)
npm run dev
```

Open http://localhost:5173 and click **Login with Keycloak**.

## Architecture

```
Browser
  ├── Click "Login" → Express → redirects to Keycloak login page
  ├── User authenticates on Keycloak
  ├── Keycloak → /auth/callback with code
  ├── Express exchanges code via generated SDK
  ├── id_token → React → ConvexProviderWithAuth
  └── Convex validates JWT via Keycloak's JWKS (through ngrok)
```

## Keycloak vs Hydra PoC

| Aspect | Keycloak PoC | Hydra PoC |
|---|---|---|
| Login UI | Keycloak's built-in page | Custom auto-accept endpoints |
| Server-side flow | Browser hits Keycloak directly | Entire flow server-side |
| User management | Keycloak admin console | Hardcoded `poc-user` |
| Complexity | Simpler (fewer moving parts) | More complex (consent app) |
