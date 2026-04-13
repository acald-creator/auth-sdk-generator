// Shared types for Auth SDK Studio

// OAuth specification type
type authSpec = {
  name: string,
  clientId: string,
  clientSecret: option<string>,
  authorizeUrl: string,
  tokenUrl: string,
  introspectUrl: option<string>,
  revokeUrl: option<string>,
  redirectUri: string,
  scopes: array<string>,
}

// Create empty spec
let emptySpec = {
  name: "",
  clientId: "",
  clientSecret: None,
  authorizeUrl: "",
  tokenUrl: "",
  introspectUrl: None,
  revokeUrl: None,
  redirectUri: "http://localhost:3000/callback",
  scopes: [],
}