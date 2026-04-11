# GitHub OAuth Demo

Live demo using a **generated** TypeScript SDK to authenticate with GitHub.

## Prerequisites

- Node.js 20+
- The auth-sdk-generator built (`make build` from the repo root)

## Setup

### 1. Create a GitHub OAuth App

1. Go to **GitHub Settings** > **Developer settings** > **OAuth Apps** > **New OAuth App**
2. Fill in:
   - **Application name**: Auth SDK Demo
   - **Homepage URL**: `http://localhost:3000`
   - **Authorization callback URL**: `http://localhost:3000/callback`
3. Click **Register application**
4. Copy the **Client ID**
5. Click **Generate a new client secret** and copy it

### 2. Generate the SDK

From the repo root:

```bash
./_build/default/bin/main.exe specs/github.auth examples/github-oauth-demo/sdk
```

### 3. Configure credentials

```bash
cd examples/github-oauth-demo
cp .env.example .env
```

Edit `.env` and paste your Client ID and Client Secret.

### 4. Install dependencies and build the SDK

```bash
npm install
npm run build:sdk
```

### 5. Run the demo

```bash
npm start
```

Open [http://localhost:3000](http://localhost:3000) and click **Login with GitHub**.

## What this demonstrates

1. **SDK Generation** -- The TypeScript OAuth2 client was generated from `specs/github.auth` by the OCaml generator
2. **PKCE Flow** -- The generated SDK creates a code verifier and S256 challenge automatically
3. **Token Exchange** -- The server exchanges the authorization code for an access token
4. **API Usage** -- The access token is used to fetch your GitHub profile
