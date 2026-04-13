
/**
 * Generated TypeScript OAuth 2.0 Client
 * Specification: ID.me Sandbox
 * Provider: default
 * Generated at: 2026-04-12 23:05:29 UTC
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
  private static readonly DEFAULT_AUTHORIZE_URL = 'https://api.idmelabs.com/oauth/authorize';
  private static readonly DEFAULT_TOKEN_URL = 'https://api.idmelabs.com/oauth/token';
  private static readonly DEFAULT_INTROSPECT_URL = '';
  private static readonly DEFAULT_REVOKE_URL = '';
  private static readonly DEFAULT_SCOPES = ["openid"];

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

  /**
   * Exchange authorization code for tokens
   */
  async exchangeCode(code: string, state?: string): Promise<TokenSet> {
    const tokenRequest: Record<string, string> = {
      grant_type: 'authorization_code',
      client_id: this.config.clientId,
      code: code,
      redirect_uri: this.config.redirectUri,
      code_verifier: this.codeVerifier,
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
    const encoder = new TextEncoder();
    const data = encoder.encode(verifier);
    const digest = await crypto.subtle.digest('SHA-256', data);
    return btoa(String.fromCharCode(...new Uint8Array(digest)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  }

  private buildAuthUrl(codeChallenge: string): string {
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: this.config.clientId,
      redirect_uri: this.config.redirectUri,
      scope: (this.config.scopes || []).join(' '),
      code_challenge: codeChallenge,
      code_challenge_method: 'S256',
      state: crypto.randomUUID(),
      ...this.config.extraParams,
    });

    return `${this.authorizeUrl}?${params.toString()}`;
  }

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
