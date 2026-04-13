# Login.gov Sandbox Auth SDK

Generated OAuth 2.0 authentication SDK with PKCE support.

## Installation

```bash
npm install
npm run build
```

## Usage

```typescript
import OAuth2Client from './src/index';

const client = new OAuth2Client({
  clientId: 'your-logingov-client-id',
  redirectUri: 'http://localhost:3000/callback',
  scopes: ['openid email']
});

// Start authentication
const authUrl = await client.startAuth();
window.location.href = authUrl;

// Handle callback (extract code from URL parameters)
const urlParams = new URLSearchParams(window.location.search);
const code = urlParams.get('code');
const state = urlParams.get('state');

if (code) {
  const tokens = await client.exchangeCode(code, state);
  console.log('Access token:', tokens.access_token);
}
```

## Generated Configuration

- **Provider**: default
- **Authorize URL**: https://idp.int.identitysandbox.gov/openid_connect/authorize
- **Token URL**: https://idp.int.identitysandbox.gov/api/openid_connect/token
- **Default Scopes**: openid email
- **PKCE**: Enabled (S256)
- **State Parameter**: Required

## Development

This SDK was generated using the OCaml-based auth SDK generator.
To regenerate, run the generator with your updated specification.
