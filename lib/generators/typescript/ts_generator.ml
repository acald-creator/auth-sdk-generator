open Ast.Auth_types

let generate_oauth2_client (spec : auth_spec) (provider : provider) =
  let pkce_code_challenge_method = match spec.protocol with
    | OAuth2 config -> match config.pkce_method with
      | S256 -> "'S256'"
      | Plain -> "'plain'"
      | NoPKCE -> "undefined"
  in

  let pkce_impl = match spec.protocol with
    | OAuth2 config when config.pkce_method <> NoPKCE -> {|
  // PKCE Implementation (RFC 7636)
  private generateCodeVerifier(): string {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return btoa(String.fromCharCode(...array))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  }

  private async generateCodeChallenge(verifier: string): Promise<string> {
|} ^ (if config.pkce_method = S256 then {|
    const encoder = new TextEncoder();
    const data = encoder.encode(verifier);
    const digest = await crypto.subtle.digest('SHA-256', data);
    return btoa(String.fromCharCode(...new Uint8Array(digest)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
|} else {|
    return verifier;
|}) ^ {|
  }
|}
    | _ -> ""
  in

  let start_auth_impl = match spec.protocol with
    | OAuth2 config when config.pkce_method <> NoPKCE -> {|
  /**
   * Start OAuth 2.0 authorization code flow with PKCE
   */
  async startAuth(): Promise<string> {
    // Generate PKCE parameters
    this.codeVerifier = this.generateCodeVerifier();
    const codeChallenge = await this.generateCodeChallenge(this.codeVerifier);

    // Build authorization URL
    const authUrl = this.buildAuthUrl(codeChallenge);

    return authUrl;
  }
|}
    | _ -> {|
  /**
   * Start OAuth 2.0 authorization code flow
   */
  async startAuth(): Promise<string> {
    // Build authorization URL
    const authUrl = this.buildAuthUrl();

    return authUrl;
  }
|}
  in

  let exchange_code_params = match spec.protocol with
    | OAuth2 config when config.pkce_method <> NoPKCE -> ",\n      code_verifier: this.codeVerifier"
    | _ -> ""
  in

  let build_auth_url_impl = match spec.protocol with
    | OAuth2 config when config.pkce_method <> NoPKCE -> {|
  private buildAuthUrl(codeChallenge: string): string {
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: this.config.clientId,
      redirect_uri: this.config.redirectUri,
      scope: (this.config.scopes || []).join(' '),
      code_challenge: codeChallenge,
      code_challenge_method: |} ^ pkce_code_challenge_method ^ {|,
      state: crypto.randomUUID(),
      ...this.config.extraParams,
    });

    return `${this.authorizeUrl}?${params.toString()}`;
  }
|}
    | _ -> {|
  private buildAuthUrl(): string {
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: this.config.clientId,
      redirect_uri: this.config.redirectUri,
      scope: (this.config.scopes || []).join(' '),
      state: crypto.randomUUID(),
      ...this.config.extraParams,
    });

    return `${this.authorizeUrl}?${params.toString()}`;
  }
|}
  in

  Printf.sprintf {|
/**
 * Generated TypeScript OAuth 2.0 Client
 * Specification: %s
 * Provider: %s
 * Generated at: %s
 */

export interface AuthConfig {
  clientId: string;
  clientSecret?: string;
  redirectUri: string;
  authorizeUrl?: string;
  tokenUrl?: string;
  introspectUrl?: string;
  revokeUrl?: string;
  scopes?: string[];
  extraParams?: Record<string, string>;
}

export interface TokenSet {
  access_token: string;
  refresh_token?: string;
  expires_in: number;
  token_type: string;
  scope?: string;
}

export interface AuthError extends Error {
  code: string;
  description?: string;
  uri?: string;
}

export class OAuth2Client {
  private config: AuthConfig;
  private codeVerifier: string = '';
  private readonly authorizeUrl: string;
  private readonly tokenUrl: string;
  private readonly introspectUrl: string;
  private readonly revokeUrl: string;
  private currentTokens: (TokenSet & { expires_at: number }) | null = null;

  // Default OAuth 2.0 endpoints (generated from spec)
  private static readonly DEFAULT_AUTHORIZE_URL = '%s';
  private static readonly DEFAULT_TOKEN_URL = '%s';
  private static readonly DEFAULT_INTROSPECT_URL = '%s';
  private static readonly DEFAULT_REVOKE_URL = '%s';
  private static readonly DEFAULT_SCOPES = %s;

  constructor(config: AuthConfig) {
    this.config = {
      scopes: OAuth2Client.DEFAULT_SCOPES,
      ...config
    };
    this.authorizeUrl = config.authorizeUrl ?? OAuth2Client.DEFAULT_AUTHORIZE_URL;
    this.tokenUrl = config.tokenUrl ?? OAuth2Client.DEFAULT_TOKEN_URL;
    this.introspectUrl = config.introspectUrl ?? OAuth2Client.DEFAULT_INTROSPECT_URL;
    this.revokeUrl = config.revokeUrl ?? OAuth2Client.DEFAULT_REVOKE_URL;
  }
%s
  /**
   * Exchange authorization code for tokens
   */
  async exchangeCode(code: string, state?: string): Promise<TokenSet> {
    const tokenRequest: Record<string, string> = {
      grant_type: 'authorization_code',
      client_id: this.config.clientId,
      code: code,
      redirect_uri: this.config.redirectUri%s
    };

    if (this.config.clientSecret) {
      tokenRequest.client_secret = this.config.clientSecret;
    }

    const response = await fetch(this.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: new URLSearchParams(tokenRequest),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({})) as Record<string, string>;
      throw this.createAuthError(
        error.error || 'token_exchange_failed',
        error.error_description || `HTTP ${response.status}`,
        error.error_uri
      );
    }

    const tokens: TokenSet = await response.json() as TokenSet;
    this.currentTokens = {
      ...tokens,
      expires_at: Date.now() + tokens.expires_in * 1000,
    };
    return tokens;
  }

  /**
   * Refresh access token
   */
  async refreshToken(refreshToken: string): Promise<TokenSet> {
    const tokenRequest: Record<string, string> = {
      grant_type: 'refresh_token',
      client_id: this.config.clientId,
      refresh_token: refreshToken,
    };

    if (this.config.clientSecret) {
      tokenRequest.client_secret = this.config.clientSecret;
    }

    const response = await fetch(this.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: new URLSearchParams(tokenRequest),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({})) as Record<string, string>;
      throw this.createAuthError(
        error.error || 'refresh_failed',
        error.error_description || `HTTP ${response.status}`,
        error.error_uri
      );
    }

    const tokens: TokenSet = await response.json() as TokenSet;
    this.currentTokens = {
      ...tokens,
      expires_at: Date.now() + tokens.expires_in * 1000,
    };
    return tokens;
  }

  /**
   * Get a valid access token, refreshing automatically if expired.
   * Returns null if no tokens are stored and no refresh is possible.
   */
  async getAccessToken(): Promise<string | null> {
    if (!this.currentTokens) {
      return null;
    }

    // Check if token is expired (with 60-second buffer)
    const isExpired = Date.now() >= this.currentTokens.expires_at - 60_000;

    if (!isExpired) {
      return this.currentTokens.access_token;
    }

    // Try to refresh
    if (this.currentTokens.refresh_token) {
      const refreshed = await this.refreshToken(this.currentTokens.refresh_token);
      return refreshed.access_token;
    }

    // Token expired, no refresh token available
    return null;
  }

  /**
   * Introspect a token to check if it is active (RFC 7662)
   */
  async introspectToken(token: string): Promise<Record<string, unknown>> {
    const body: Record<string, string> = { token };
    if (this.config.clientId) body.client_id = this.config.clientId;
    if (this.config.clientSecret) body.client_secret = this.config.clientSecret;

    const response = await fetch(this.introspectUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: new URLSearchParams(body),
    });

    return await response.json() as Record<string, unknown>;
  }

  /**
   * Revoke a token (RFC 7009)
   */
  async revokeToken(token: string): Promise<void> {
    const body: Record<string, string> = { token };
    if (this.config.clientId) body.client_id = this.config.clientId;
    if (this.config.clientSecret) body.client_secret = this.config.clientSecret;

    await fetch(this.revokeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams(body),
    });
  }
%s
%s
  private createAuthError(code: string, description?: string, uri?: string): AuthError {
    const error = new Error(description || code) as AuthError;
    error.code = code;
    if (description !== undefined) {
      error.description = description;
    }
    if (uri !== undefined) {
      error.uri = uri;
    }
    return error;
  }
}

// Export for convenience
export default OAuth2Client;
|}
    spec.name
    provider.name
    (let now = Unix.time () |> Unix.gmtime in
     Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d UTC"
       (now.tm_year + 1900) (now.tm_mon + 1) now.tm_mday
       now.tm_hour now.tm_min now.tm_sec)
    provider.authorize_url
    provider.token_url
    (match provider.introspect_url with Some u -> u | None -> "")
    (match provider.revoke_url with Some u -> u | None -> "")
    (let scopes_str = provider.scopes
                     |> List.map (fun s -> "\"" ^ s ^ "\"")
                     |> String.concat ", " in
     "[" ^ scopes_str ^ "]")
    start_auth_impl
    exchange_code_params
    pkce_impl
    build_auth_url_impl

let generate_package_json ?(use_fallback_versions=false) (provider : provider) =
  (* Fetch latest versions for dev dependencies *)
  let versions = Utils.Version_fetcher.get_typescript_versions ~use_fallback_first:use_fallback_versions () in
  let _ = Utils.Version_fetcher.validate_package_versions versions in
  let get_version name = List.assoc name versions in

  Printf.sprintf {|{
  "name": "%s-auth-sdk",
  "version": "1.0.0-prototype",
  "description": "Generated OAuth 2.0 authentication SDK",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "dev": "tsc --watch"
  },
  "keywords": ["oauth2", "authentication", "pkce", "generated"],
  "dependencies": {},
  "devDependencies": {
    "typescript": "^%s",
    "@types/node": "^%s",
    "jest": "^%s",
    "@types/jest": "^%s"
  },
  "files": ["dist/**/*", "README.md"]
}|} (String.map (function ' ' -> '-' | c -> c) (String.lowercase_ascii provider.name))
    (get_version "typescript")
    (get_version "@types/node")
    (get_version "jest")
    (get_version "@types/jest")

let generate_tsconfig () = {|{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020", "DOM"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}|}

let generate_readme (spec : auth_spec) (provider : provider) =
  let pkce_status = match spec.protocol with
    | OAuth2 config -> (match config.pkce_method with
      | S256 -> "Enabled (S256)"
      | Plain -> "Enabled (plain)"
      | NoPKCE -> "Disabled")
  in
  Printf.sprintf {|# %s Auth SDK

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
  clientId: '%s',
  redirectUri: 'http://localhost:3000/callback',
  scopes: %s
});

// Start authentication
const authUrl = await client.start_auth();
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

- **Provider**: %s
- **Authorize URL**: %s
- **Token URL**: %s
- **Default Scopes**: %s
- **PKCE**: %s
- **State Parameter**: Required

## Development

This SDK was generated using the OCaml-based auth SDK generator.
To regenerate, run the generator with your updated specification.
|} spec.name provider.client_id
   (let scopes_str = provider.scopes
                    |> List.map (fun s -> "'" ^ s ^ "'")
                    |> String.concat ", " in
    "[" ^ scopes_str ^ "]")
   provider.name provider.authorize_url provider.token_url
   (String.concat ", " provider.scopes)
   pkce_status

(** Main generation function *)
let generate_typescript_sdk ?(use_fallback_versions=false) (spec : auth_spec) output_dir =
  let provider = List.hd spec.providers in (* Use first provider for prototype *)

  (* Generate source files *)
  let client_code = generate_oauth2_client spec provider in
  let package_json = generate_package_json ~use_fallback_versions provider in
  let tsconfig = generate_tsconfig () in
  let readme = generate_readme spec provider in

  (* Create directory structure *)
  let src_dir = Filename.concat output_dir "src" in
  (try Unix.mkdir output_dir 0o755 with Unix.Unix_error (EEXIST, _, _) -> ());
  (try Unix.mkdir src_dir 0o755 with Unix.Unix_error (EEXIST, _, _) -> ());

  (* Write files *)
  let write_file filename content =
    let oc = open_out filename in
    output_string oc content;
    close_out oc
  in
  write_file (Filename.concat src_dir "index.ts") client_code;
  write_file (Filename.concat output_dir "package.json") package_json;
  write_file (Filename.concat output_dir "tsconfig.json") tsconfig;
  write_file (Filename.concat output_dir "README.md") readme;

  Printf.printf "✅ Generated TypeScript SDK in %s\n" output_dir;
  Printf.printf "   - Source: %s/index.ts\n" src_dir;
  Printf.printf "   - Config: package.json, tsconfig.json\n";
  Printf.printf "   - Docs: README.md\n"