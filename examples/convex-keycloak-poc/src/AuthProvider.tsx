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

export function KeycloakAuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<AuthState>({
    isLoading: true,
    isAuthenticated: false,
    sessionId: null,
    idToken: null,
  });

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const session = params.get("session");

    if (session) {
      window.history.replaceState({}, "", "/");

      fetch(`/auth/token?session=${session}`)
        .then((res) => res.json())
        .then((data) => {
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
        .catch(() => {
          setAuth({ isLoading: false, isAuthenticated: false, sessionId: null, idToken: null });
        });
    } else {
      setAuth({ isLoading: false, isAuthenticated: false, sessionId: null, idToken: null });
    }
  }, []);

  return <AuthContext.Provider value={auth}>{children}</AuthContext.Provider>;
}

// Hook for Convex
export function useAuthFromKeycloak() {
  const auth = useContext(AuthContext);

  const fetchAccessToken = useCallback(
    async ({ forceRefreshToken: _ }: { forceRefreshToken: boolean }) => {
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

// Hook for App component
export function useKeycloakAuth() {
  return useContext(AuthContext);
}
