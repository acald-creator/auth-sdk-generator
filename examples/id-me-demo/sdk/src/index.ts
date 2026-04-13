
/**
 * Generated High-Integrity OAuth 2.0 Client
 * Factory: Auth SDK Generator
 * Foundation: @cosmonexus/oauth-client
 * Specification: ID.me Sandbox
 */

import { OAuthClient } from "@cosmonexus/oauth-client";
import { TokenManager } from "@cosmonexus/oauth-tokens";
import { AuthProvider as BaseProvider, LoginButton } from "@cosmonexus/oauth-react";
import React, { useMemo } from "react";

/**
 * IDmeSandboxClient - A specialized, high-integrity SDK for ID.me Sandbox.
 * 
 * This SDK is built upon the @cosmonexus foundation, providing:
 * - Bulletproof PKCE (S256) implementation
 * - Secure URL sanitization (CRLF defense)
 * - Stateful token management with proactive refreshing
 * - Cross-tab synchronization
 */
export class IDmeSandboxClient extends OAuthClient {
  constructor(config: any = {}) {
    super({
      issuerBaseUrl: "https://api.idmelabs.com",
      authorizePath: "https://api.idmelabs.com/oauth/authorize",
      tokenPath: "https://api.idmelabs.com/oauth/token",
      logoutPath: "/logout",
      scopes: ["openid"],
      ...config
    });
  }
}

/**
 * IDmeSandboxProvider - React Context Provider specialized for ID.me Sandbox.
 */
export function IDmeSandboxProvider({ config, children }: any) {
  const mergedConfig = useMemo(() => ({
    issuerBaseUrl: "https://api.idmelabs.com",
    authorizePath: "https://api.idmelabs.com/oauth/authorize",
    tokenPath: "https://api.idmelabs.com/oauth/token",
    logoutPath: "/logout",
    scopes: ["openid"],
    ...config
  }), [config]);

  return React.createElement(BaseProvider, { config: mergedConfig }, children);
}

/**
 * IDmeSandboxLoginButton - Specialized login button for ID.me Sandbox.
 */
export function IDmeSandboxLoginButton(props: any) {
  return React.createElement(LoginButton, {
    provider: "default",
    label: "Sign in with ID.me Sandbox",
    ...props
  });
}
