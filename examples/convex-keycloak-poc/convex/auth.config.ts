import { AuthConfig } from "convex/server";

// UPDATE THIS to your ngrok URL: https://YOUR-ID.ngrok-free.app/realms/demo
const KEYCLOAK_ISSUER = "https://YOUR-NGROK-ID.ngrok-free.app/realms/demo";

export default {
  providers: [
    {
      type: "customJwt" as const,
      issuer: KEYCLOAK_ISSUER,
      jwks: `${KEYCLOAK_ISSUER}/protocol/openid-connect/certs`,
      algorithm: "RS256" as const,
      applicationID: "demo-client",
    },
  ],
} satisfies AuthConfig;
