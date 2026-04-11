import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

interface AuthState {
  isLoading: boolean;
  isAuthenticated: boolean;
  sessionId: string | null;
  idToken: string | null;
}

const AuthContext = createContext<AuthState>({
  isLoading: true,
  isAuthenticated: false,
  sessionId: null,
  idToken: null,
});

// Provider component that manages the auth state once
export function HydraAuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState>({
    isLoading: true,
    isAuthenticated: false,
    sessionId: null,
    idToken: null,
  });

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const session = params.get("session");

    console.log("[AuthProvider] mount, session param:", session);

    if (session) {
      window.history.replaceState({}, "", "/");

      fetch(`/auth/token?session=${session}`)
        .then((res) => res.json())
        .then((data) => {
          console.log("[AuthProvider] /auth/token response:", {
            authenticated: data.authenticated,
            hasIdToken: !!data.idToken,
            idTokenLength: data.idToken?.length,
          });

          if (data.idToken) {
            try {
              const payload = data.idToken.split(".")[1];
              const claims = JSON.parse(atob(payload));
              console.log("[AuthProvider] JWT claims:", {
                iss: claims.iss,
                aud: claims.aud,
                sub: claims.sub,
              });
            } catch (e) {
              console.error("[AuthProvider] Failed to decode JWT:", e);
            }
          }

          if (data.authenticated && data.idToken) {
            setAuth({
              isLoading: false,
              isAuthenticated: true,
              sessionId: session,
              idToken: data.idToken,
            });
          } else {
            setAuth({ isLoading: false, isAuthenticated: false, sessionId: null, idToken: null });
          }
        })
        .catch((err) => {
          console.error("[AuthProvider] fetch error:", err);
          setAuth({ isLoading: false, isAuthenticated: false, sessionId: null, idToken: null });
        });
    } else {
      setAuth({ isLoading: false, isAuthenticated: false, sessionId: null, idToken: null });
    }
  }, []);

  return <AuthContext.Provider value={auth}>{children}</AuthContext.Provider>;
}

// Hook for Convex — reads from the shared context
export function useAuthFromHydra() {
  const auth = useContext(AuthContext);

  const fetchAccessToken = useCallback(
    async ({ forceRefreshToken }: { forceRefreshToken: boolean }) => {
      console.log("[useAuthFromHydra] fetchAccessToken called", {
        forceRefreshToken,
        hasToken: !!auth.idToken,
      });
      return auth.idToken;
    },
    [auth.idToken],
  );

  return useMemo(
    () => ({
      isLoading: auth.isLoading,
      isAuthenticated: auth.isAuthenticated,
      fetchAccessToken,
    }),
    [auth.isLoading, auth.isAuthenticated, fetchAccessToken],
  );
}

// Hook for App component — reads from the shared context
export function useHydraAuth() {
  return useContext(AuthContext);
}
