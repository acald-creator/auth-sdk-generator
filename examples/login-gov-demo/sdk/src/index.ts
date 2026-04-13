
/**
 * Generated High-Integrity OAuth 2.0 Client
 * Factory: Auth SDK Generator
 * Foundation: @oauth-pkce/client
 * Specification: Login.gov Sandbox
 */

import { OAuthClient } from "@oauth-pkce/client";
import { TokenManager } from "@oauth-pkce/tokens";
import { AuthProvider as BaseProvider, LoginButton } from "@oauth-pkce/react";
import React, { useMemo } from "react";

/**
 * LogingovSandboxClient - A specialized, high-integrity SDK for Login.gov Sandbox.
 * 
 * This SDK is built upon the @oauth-pkce foundation, providing:
 * - Bulletproof PKCE (S256) implementation
 * - Secure URL sanitization (CRLF defense)
 * - Stateful token management with proactive refreshing
 * - Cross-tab synchronization
 */
export class LogingovSandboxClient extends OAuthClient {
  constructor(config: any = {}) {
    super({
      issuerBaseUrl: "https://idp.int.identitysandbox.gov",
      authorizePath: "https://idp.int.identitysandbox.gov/openid_connect/authorize",
      tokenPath: "https://idp.int.identitysandbox.gov/api/openid_connect/token",
      logoutPath: "/logout",
      scopes: ["openid email"],
      ...config
    });
  }
}

/**
 * LogingovSandboxProvider - React Context Provider specialized for Login.gov Sandbox.
 */
export function LogingovSandboxProvider({ config, children }: any) {
  const mergedConfig = useMemo(() => ({
    issuerBaseUrl: "https://idp.int.identitysandbox.gov",
    authorizePath: "https://idp.int.identitysandbox.gov/openid_connect/authorize",
    tokenPath: "https://idp.int.identitysandbox.gov/api/openid_connect/token",
    logoutPath: "/logout",
    scopes: ["openid email"],
    ...config
  }), [config]);

  return React.createElement(BaseProvider, { config: mergedConfig }, children);
}

/**
 * LogingovSandboxLoginButton - Specialized login button for Login.gov Sandbox.
 */
export function LogingovSandboxLoginButton(props: any) {
  return React.createElement(LoginButton, {
    provider: "default",
    label: "Sign in with Login.gov Sandbox",
    ...props
  });
}
