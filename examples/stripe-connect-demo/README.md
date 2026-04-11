# Stripe Connect Demo

Live demo using a **generated** TypeScript SDK to connect Stripe accounts via OAuth.

Demonstrates three production features:
- **#17 Runtime Config** - endpoint URLs overridable at runtime (test vs live)
- **#18 Token Lifecycle** - `getAccessToken()` with automatic token refresh
- **#19 Client Secret** - `client_secret` included in token exchanges automatically

## Prerequisites

- Node.js 20+
- The auth-sdk-generator built (`make build` from the repo root)
- A Stripe account with Connect enabled

## Setup

### 1. Enable Stripe Connect

1. Go to [Stripe Dashboard](https://dashboard.stripe.com) > **Settings** > **Connect settings**
2. Enable Connect for your platform
3. Under **OAuth settings**, set the redirect URI to `http://localhost:3000/callback`
4. Copy your **Client ID** (starts with `ca_`)
5. Copy your **Secret Key** from **Developers** > **API keys** (starts with `sk_test_`)

### 2. Generate the SDK

From the repo root:

```bash
./_build/default/bin/main.exe specs/stripe-connect.auth examples/stripe-connect-demo/sdk
```

### 3. Configure credentials

```bash
cd examples/stripe-connect-demo
cp .env.example .env
```

Edit `.env` with your Stripe Client ID and Secret Key.

### 4. Install dependencies and build the SDK

```bash
npm install
npm run build:sdk
```

### 5. Run the demo

```bash
npm start
```

Open [http://localhost:3000](http://localhost:3000) and click **Connect with Stripe**.

## What this demonstrates

1. **SDK Generation** - The TypeScript OAuth2 client was generated from `specs/stripe-connect.auth` (7 lines)
2. **Client Secret** - The generated `exchangeCode()` method automatically includes `client_secret` in the token request
3. **Runtime Config** - Endpoint URLs are configurable at runtime, with generated defaults as fallbacks
4. **Token Lifecycle** - `getAccessToken()` returns a cached token or auto-refreshes if expired
5. **PKCE Flow** - Code verifier and S256 challenge are generated automatically
