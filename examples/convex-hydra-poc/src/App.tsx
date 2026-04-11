import { useQuery } from "convex/react";
import { api } from "../convex/_generated/api";
import { useHydraAuth } from "./AuthProvider";
import "./App.css";

export default function App() {
  const auth = useHydraAuth();
  const identity = useQuery(api.tasks.whoami);

  if (auth.isLoading) {
    return (
      <div className="container">
        <h1>Convex + Ory Hydra</h1>
        <p className="loading">Loading...</p>
      </div>
    );
  }

  return (
    <div className="container">
      <h1>Convex + Ory Hydra PoC</h1>
      <p className="subtitle">
        Custom auth using a <strong>generated</strong> OAuth2 SDK
      </p>

      {!auth.isAuthenticated ? (
        <div className="card">
          <p>Not authenticated. Login via Ory Hydra to access Convex data.</p>
          <a className="btn" href="/auth/login">
            Login with Hydra
          </a>
        </div>
      ) : (
        <div className="card authenticated">
          <h2>Authenticated</h2>

          {identity ? (
            <div className="identity">
              <div className="field">
                <label>Subject</label>
                <span>{identity.subject}</span>
              </div>
              <div className="field">
                <label>Issuer</label>
                <span>{identity.issuer}</span>
              </div>
              {identity.name && (
                <div className="field">
                  <label>Name</label>
                  <span>{identity.name}</span>
                </div>
              )}
              {identity.email && (
                <div className="field">
                  <label>Email</label>
                  <span>{identity.email}</span>
                </div>
              )}
              <div className="field">
                <label>Token ID</label>
                <span className="mono">{identity.tokenIdentifier}</span>
              </div>
            </div>
          ) : identity === null ? (
            <p>Convex could not validate the token. Check auth.config.ts and Hydra issuer URL.</p>
          ) : (
            <p className="loading">Loading identity from Convex...</p>
          )}

          <button
            className="btn btn-logout"
            onClick={async () => {
              if (auth.sessionId) {
                await fetch(`/auth/logout?session=${auth.sessionId}`);
              }
              window.location.href = "/";
            }}
          >
            Logout
          </button>
        </div>
      )}

      <div className="info">
        <h3>How it works</h3>
        <ol>
          <li>Click Login → redirects to Ory Hydra (via generated SDK)</li>
          <li>Hydra authenticates and returns an authorization code</li>
          <li>Backend exchanges code for tokens using the generated SDK</li>
          <li>The <code>id_token</code> (JWT) is passed to Convex</li>
          <li>Convex validates it against Hydra's JWKS endpoint</li>
          <li>This page queries Convex with the authenticated identity</li>
        </ol>
      </div>
    </div>
  );
}
