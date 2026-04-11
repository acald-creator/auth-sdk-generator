# Keycloak Demo

Enterprise OAuth using a **generated** TypeScript SDK with Keycloak.

Unlike Ory Hydra, Keycloak provides its own login UI — no consent app needed. Users see Keycloak's login page directly.

Demonstrates:
- **OIDC** — Keycloak issues `id_token` with user claims (name, email, roles)
- **Token Introspection** (RFC 7662) — validate tokens from other services
- **Token Revocation** (RFC 7009) — revoke tokens on logout
- **Runtime Config** — realm URLs configured from `.env`

## Prerequisites

- Node.js 20+
- Docker
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

Wait ~30 seconds for startup, then open http://localhost:8080/admin and login with `admin` / `admin`.

### 2. Create a realm and client

**Create realm:**
1. Click the dropdown in the top-left (shows "Keycloak") → **Create realm**
2. Name: `demo` → **Create**

**Create client:**
1. Go to **Clients** → **Create client**
2. Client ID: `demo-client` → **Next**
3. Enable **Client authentication** → **Next**
4. Add `http://localhost:3000/callback` to **Valid redirect URIs** → **Save**
5. Go to the **Credentials** tab → copy the **Client secret**

**Create a test user:**
1. Go to **Users** → **Add user**
2. Username: `testuser`, Email: `test@example.com`, First name: `Test`, Last name: `User`
3. Click **Create**
4. Go to the **Credentials** tab → **Set password** → set `password` → disable Temporary → **Save**

### 3. Generate the SDK

From the repo root:

```bash
./_build/default/bin/main.exe specs/keycloak.auth examples/keycloak-demo/sdk
```

### 4. Configure

```bash
cd examples/keycloak-demo
cp .env.example .env
```

Edit `.env` with the client secret from step 2.

### 5. Install and run

```bash
npm install
npm run build:sdk
npm start
```

Open [http://localhost:3000](http://localhost:3000) and click **Login with Keycloak**.

## Demo Flow

1. Click Login → redirects to Keycloak's login page
2. Enter `testuser` / `password`
3. Keycloak redirects back with authorization code
4. Server exchanges code for tokens (client_secret included automatically)
5. Token introspection validates the token
6. Userinfo endpoint returns user profile
7. Click "Revoke Token" to test revocation

## Keycloak vs Ory Hydra

| Feature | Keycloak | Ory Hydra |
|---|---|---|
| Login UI | Built-in | Bring your own |
| User management | Built-in | Needs Kratos or external |
| Admin console | Web UI | API only |
| Identity federation | Google, LDAP, SAML | External |
| Realm/tenant support | Built-in | Manual |
| Footprint | Heavier (~500MB) | Lighter (~50MB) |
| Use case | Enterprise SSO | Microservice auth |
