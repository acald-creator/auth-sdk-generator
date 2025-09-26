// Shared types for Auth SDK Studio

// OAuth specification type
type authSpec = {
  name: string,
  clientId: string,
  clientSecret: option<string>,
  authorizeUrl: string,
  tokenUrl: string,
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
  redirectUri: "http://localhost:3000/callback",
  scopes: [],
}