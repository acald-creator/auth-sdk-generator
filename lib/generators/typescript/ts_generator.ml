open Ast.Auth_types

let sanitize_name name =
  let is_alphanumeric = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' -> true
    | _ -> false
  in
  let res = Buffer.create (String.length name) in
  String.iter (fun c -> if is_alphanumeric c then Buffer.add_char res c) name;
  Buffer.contents res

let get_issuer_url url =
  try
    let regex = Str.regexp "\\(https?://[^/]+\\)" in
    if Str.string_match regex url 0 then
      Str.matched_group 1 url
    else
      url
  with _ -> url

let generate_oauth2_client (spec : auth_spec) (provider : provider) =
  let client_name = sanitize_name spec.name in
  let scopes_list = 
    match provider.scopes with
    | [] -> "[]"
    | _ -> "[" ^ (provider.scopes |> List.map (fun s -> "\"" ^ s ^ "\"") |> String.concat ", ") ^ "]"
  in
  let issuer_url = get_issuer_url provider.authorize_url in
  
  let pkce_feature = match spec.protocol with
    | OAuth2 config when config.pkce_method <> NoPKCE -> " * - Bulletproof PKCE (S256) implementation\n"
    | _ -> ""
  in

  Printf.sprintf {|
/**
 * Generated High-Integrity OAuth 2.0 Client
 * Factory: Auth SDK Generator
 * Foundation: @oauth-pkce/client
 * Specification: %s
 */

import { OAuthClient } from "@oauth-pkce/client";
import { TokenManager } from "@oauth-pkce/tokens";
import { AuthProvider as BaseProvider, LoginButton } from "@oauth-pkce/react";
import React, { useMemo } from "react";

/**
 * %sClient - A specialized, high-integrity SDK for %s.
 * 
 * This SDK is built upon the @oauth-pkce foundation, providing:
%s * - Secure URL sanitization (CRLF defense)
 * - Stateful token management with proactive refreshing
 * - Cross-tab synchronization
 */
export class %sClient extends OAuthClient {
  constructor(config: any = {}) {
    super({
      issuerBaseUrl: "%s",
      authorizePath: "%s",
      tokenPath: "%s",
      logoutPath: "%s",
      scopes: %s,
      ...config
    });
  }
}

/**
 * %sProvider - React Context Provider specialized for %s.
 */
export function %sProvider({ config, children }: any) {
  const mergedConfig = useMemo(() => ({
    issuerBaseUrl: "%s",
    authorizePath: "%s",
    tokenPath: "%s",
    logoutPath: "%s",
    scopes: %s,
    ...config
  }), [config]);

  return React.createElement(BaseProvider, { config: mergedConfig }, children);
}

/**
 * %sLoginButton - Specialized login button for %s.
 */
export function %sLoginButton(props: any) {
  return React.createElement(LoginButton, {
    provider: "default",
    label: "Sign in with %s",
    ...props
  });
}
|}
    spec.name
    client_name
    spec.name
    pkce_feature
    client_name
    issuer_url
    provider.authorize_url
    provider.token_url
    (match provider.revoke_url with Some u -> u | None -> "/logout")
    scopes_list
    client_name
    spec.name
    client_name
    issuer_url
    provider.authorize_url
    provider.token_url
    (match provider.revoke_url with Some u -> u | None -> "/logout")
    scopes_list
    client_name
    spec.name
    client_name
    spec.name

let generate_package_json ?(use_fallback_versions=false) (provider : provider) =
  let versions = Utils.Version_fetcher.get_typescript_versions ~use_fallback_first:use_fallback_versions () in
  let _ = Utils.Version_fetcher.validate_package_versions versions in
  let get_version name = List.assoc name versions in

  Printf.sprintf {|{
  "name": "%s-auth-sdk",
  "version": "1.0.0-prototype",
  "description": "Generated OAuth 2.0 authentication SDK",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "dev": "tsc --watch"
  },
  "keywords": ["oauth2", "authentication", "pkce", "generated"],
  "dependencies": {
    "@oauth-pkce/client": "workspace:*",
    "@oauth-pkce/tokens": "workspace:*",
    "@oauth-pkce/react": "workspace:*",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "typescript": "^%s",
    "@types/react": "^19.0.10",
    "@types/react-dom": "^19.0.4",
    "@types/node": "^%s",
    "jest": "^%s",
    "@types/jest": "^%s"
  },
  "files": ["dist/**/*", "README.md"]
}|} (String.map (function ' ' -> '-' | c -> c) (String.lowercase_ascii provider.name))
    (get_version "typescript")
    (get_version "@types/node")
    (get_version "jest")
    (get_version "@types/jest")

let generate_tsconfig () =
  {|{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "declaration": true,
    "sourceMap": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "jsx": "react-jsx",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "**/*.test.ts"]
}
|}

let generate_readme (spec : auth_spec) (provider : provider) =
  let pkce_status = match spec.protocol with
    | OAuth2 config -> if config.pkce_method <> NoPKCE then "Enabled (S256)" else "Disabled"
  in
  let client_name = sanitize_name spec.name in
  Printf.sprintf {|# %s SDK

High-integrity TypeScript SDK for %s, generated by the Auth SDK Generator.

## Integration

This SDK is built on the `@oauth-pkce` foundation.

### React

```tsx
import { %sProvider, %sLoginButton } from './sdk';

function App() {
  return (
    <%sProvider config={{ clientId: '%s' }}>
      <%sLoginButton />
    </%sProvider>
  );
}
```

## Technical Details

- **Provider**: %s
- **Authorize URL**: %s
- **Token URL**: %s
- **Default Scopes**: %s
- **PKCE**: %s
- **State Parameter**: Required

## Development

This SDK was generated using the OCaml-based auth SDK generator.
To regenerate, run the generator with your updated specification.
|} spec.name spec.name
   client_name client_name client_name provider.client_id client_name client_name
   provider.name provider.authorize_url provider.token_url
   (String.concat ", " provider.scopes)
   pkce_status

(** Main generation function *)
let generate_typescript_sdk ?(use_fallback_versions=false) (spec : auth_spec) output_dir =
  let provider = List.hd spec.providers in

  let client_code = generate_oauth2_client spec provider in
  let package_json = generate_package_json ~use_fallback_versions provider in
  let tsconfig = generate_tsconfig () in
  let readme = generate_readme spec provider in

  let src_dir = Filename.concat output_dir "src" in
  (try Unix.mkdir output_dir 0o755 with Unix.Unix_error (EEXIST, _, _) -> ());
  (try Unix.mkdir src_dir 0o755 with Unix.Unix_error (EEXIST, _, _) -> ());

  let write_file filename content =
    let oc = open_out filename in
    output_string oc content;
    close_out oc
  in
  write_file (Filename.concat src_dir "index.ts") client_code;
  write_file (Filename.concat output_dir "package.json") package_json;
  write_file (Filename.concat output_dir "tsconfig.json") tsconfig;
  write_file (Filename.concat output_dir "README.md") readme;

  Printf.printf "✅ Generated TypeScript SDK in %s\n" output_dir;
  Printf.printf "   - Source: %s/index.ts\n" src_dir;
  Printf.printf "   - Config: package.json, tsconfig.json\n";
  Printf.printf "   - Docs: README.md\n"
