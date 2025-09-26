// ReScript bindings for the OCaml auth-sdk-generator JavaScript interface

// Type for the auth spec that matches the JavaScript interface
type authSpec = {
  name: string,
  clientId: string,
  clientSecret: option<string>,
  authorizeUrl: string,
  tokenUrl: string,
  redirectUri: string,
  scopes: array<string>,
}

// External bindings to the compiled OCaml JavaScript functions
@val @scope("globalThis.AuthSDKGenerator")
external generateTypeScript: (authSpec, string) => unit = "generateTypeScript"

@val @scope("globalThis.AuthSDKGenerator")
external generatePython: (authSpec, string) => unit = "generatePython"

// Helper function to convert ReScript authSpec to match Types.authSpec
let convertToAuthSpec = (spec: Types.authSpec): authSpec => {
  {
    name: spec.name,
    clientId: spec.clientId,
    clientSecret: spec.clientSecret,
    authorizeUrl: spec.authorizeUrl,
    tokenUrl: spec.tokenUrl,
    redirectUri: spec.redirectUri,
    scopes: spec.scopes,
  }
}

// High-level functions for generating SDKs
let generateTypeScriptSDK = (spec: Types.authSpec, outputDir: string): unit => {
  let convertedSpec = convertToAuthSpec(spec)
  generateTypeScript(convertedSpec, outputDir)
}

let generatePythonSDK = (spec: Types.authSpec, outputDir: string): unit => {
  let convertedSpec = convertToAuthSpec(spec)
  generatePython(convertedSpec, outputDir)
}