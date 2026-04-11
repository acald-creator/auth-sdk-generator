import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { ConvexProviderWithAuth, ConvexReactClient } from "convex/react";
import { HydraAuthProvider, useAuthFromHydra } from "./AuthProvider";
import App from "./App";

const convex = new ConvexReactClient(import.meta.env.VITE_CONVEX_URL as string);

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <HydraAuthProvider>
      <ConvexProviderWithAuth client={convex} useAuth={useAuthFromHydra}>
        <App />
      </ConvexProviderWithAuth>
    </HydraAuthProvider>
  </StrictMode>,
);
