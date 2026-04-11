import { AuthConfig } from "convex/server";

// UPDATE THIS to your ngrok URL when running the PoC
const HYDRA_ISSUER = "https://YOUR-NGROK-ID.ngrok-free.app";

export default {
  providers: [
    {
      // Use customJwt for explicit JWKS URL (works with local Convex backend)
      type: "customJwt" as const,
      issuer: HYDRA_ISSUER,
      jwks: `${HYDRA_ISSUER}/.well-known/jwks.json`,
      algorithm: "RS256" as const,
      applicationID: "convex-hydra-poc",
    },
  ],
} satisfies AuthConfig;
