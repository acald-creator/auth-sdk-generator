
/**
 * Generated High-Integrity OAuth 2.0 Client
 * Factory: Auth SDK Generator
 * Foundation: @cosmonexus/oauth-client
 * Specification: Ory Hydra
 */

import { OAuthClient } from "@cosmonexus/oauth-client";
import { TokenManager } from "@cosmonexus/oauth-tokens";
import { AuthProvider as BaseProvider, LoginButton } from "@cosmonexus/oauth-react";
import React, { useMemo } from "react";

/**
 * OryHydraClient - A specialized, high-integrity SDK for Ory Hydra.
 * 
 * This SDK is built upon the @cosmonexus foundation, providing:
 * - Bulletproof PKCE (S256) implementation
 * - Secure URL sanitization (CRLF defense)
 * - Stateful token management with proactive refreshing
 * - Cross-tab synchronization
 */
export class OryHydraClient extends OAuthClient {
  constructor(config: any = {}) {
    super({
      issuerBaseUrl: "http://127.0.0.1:4444",
      authorizePath: "http://127.0.0.1:4444/oauth2/auth",
      tokenPath: "http://127.0.0.1:4444/oauth2/token",
      logoutPath: "http://127.0.0.1:4444/oauth2/revoke",
      scopes: ["openid", "offline_access", "profile", "email"],
      ...config
    });
  }
}

/**
 * OryHydraProvider - React Context Provider specialized for Ory Hydra.
 */
export function OryHydraProvider({ config, children }: any) {
  const mergedConfig = useMemo(() => ({
    issuerBaseUrl: "http://127.0.0.1:4444",
    authorizePath: "http://127.0.0.1:4444/oauth2/auth",
    tokenPath: "http://127.0.0.1:4444/oauth2/token",
    logoutPath: "http://127.0.0.1:4444/oauth2/revoke",
    scopes: ["openid", "offline_access", "profile", "email"],
    ...config
  }), [config]);

  return React.createElement(BaseProvider, { config: mergedConfig }, children);
}

/**
 * OryHydraLoginButton - Specialized login button for Ory Hydra.
 */
export function OryHydraLoginButton(props: any) {
  return React.createElement(LoginButton, {
    provider: "default",
    label: "Sign in with Ory Hydra",
    ...props
  });
}
