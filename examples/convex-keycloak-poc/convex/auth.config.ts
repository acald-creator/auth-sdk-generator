import { AuthConfig } from "convex/server";

// The issuer must match the `iss` field in Keycloak's id_tokens.
// Keycloak uses its configured frontend URL as the issuer.
const KEYCLOAK_ISSUER = "http://localhost:8080/realms/demo";

// UPDATE THIS to your ngrok URL for JWKS fetching by Convex Cloud
const KEYCLOAK_NGROK = "https://YOUR-NGROK-ID.ngrok-free.app";

export default {
  providers: [
    {
      type: "customJwt" as const,
      // Must match JWT iss claim
      issuer: KEYCLOAK_ISSUER,
      // Convex fetches keys from this URL (via ngrok since Keycloak is local)
      jwks: `${KEYCLOAK_NGROK}/realms/demo/protocol/openid-connect/certs`,
      algorithm: "RS256" as const,
      applicationID: "demo-client",
    },
  ],
} satisfies AuthConfig;
