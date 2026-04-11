open Test_helpers

let client_code =
  lazy (Typescript_generator.Ts_generator.generate_oauth2_client sample_spec sample_provider)

let test_contains_class () =
  check_contains ~msg:"has OAuth2Client class"
    (Lazy.force client_code) "class OAuth2Client"

let test_contains_provider_urls () =
  let code = Lazy.force client_code in
  check_contains ~msg:"authorize_url" code "https://auth.example.com/authorize";
  check_contains ~msg:"token_url" code "https://auth.example.com/token"

let test_contains_scopes () =
  let code = Lazy.force client_code in
  check_contains ~msg:"read scope" code "\"read\"";
  check_contains ~msg:"write scope" code "\"write\""

let test_contains_pkce_methods () =
  let code = Lazy.force client_code in
  check_contains ~msg:"generateCodeVerifier" code "generateCodeVerifier";
  check_contains ~msg:"generateCodeChallenge" code "generateCodeChallenge"

let test_contains_interfaces () =
  let code = Lazy.force client_code in
  check_contains ~msg:"AuthConfig" code "interface AuthConfig";
  check_contains ~msg:"TokenSet" code "interface TokenSet";
  check_contains ~msg:"AuthError" code "interface AuthError"

let test_contains_exchange_refresh () =
  let code = Lazy.force client_code in
  check_contains ~msg:"exchangeCode" code "exchangeCode";
  check_contains ~msg:"refreshToken" code "refreshToken"

let test_contains_spec_name () =
  check_contains ~msg:"spec name in header"
    (Lazy.force client_code) "Test App"

let test_package_json_versions () =
  let json = Typescript_generator.Ts_generator.generate_package_json
    ~use_fallback_versions:true sample_provider in
  check_contains ~msg:"typescript version" json "\"typescript\": \"^5.9.2\"";
  check_contains ~msg:"@types/node version" json "\"@types/node\": \"^24.5.2\""

let test_package_json_valid_json () =
  let json = Typescript_generator.Ts_generator.generate_package_json
    ~use_fallback_versions:true sample_provider in
  (* Should not raise *)
  let _ = Yojson.Safe.from_string json in
  Alcotest.(check pass) "valid JSON" () ()

let test_package_json_contains_name () =
  let json = Typescript_generator.Ts_generator.generate_package_json
    ~use_fallback_versions:true sample_provider in
  check_contains ~msg:"provider name" json "testprovider-auth-sdk"

let test_tsconfig_strict () =
  let config = Typescript_generator.Ts_generator.generate_tsconfig () in
  check_contains ~msg:"strict" config "\"strict\": true"

let test_sdk_creates_files () =
  with_temp_dir (fun dir ->
    Typescript_generator.Ts_generator.generate_typescript_sdk
      ~use_fallback_versions:true sample_spec dir;
    Alcotest.(check bool) "src/index.ts exists" true
      (Sys.file_exists (Filename.concat (Filename.concat dir "src") "index.ts"));
    Alcotest.(check bool) "package.json exists" true
      (Sys.file_exists (Filename.concat dir "package.json"));
    Alcotest.(check bool) "tsconfig.json exists" true
      (Sys.file_exists (Filename.concat dir "tsconfig.json"));
    Alcotest.(check bool) "README.md exists" true
      (Sys.file_exists (Filename.concat dir "README.md"))
  )

let test_sdk_index_contains_class () =
  with_temp_dir (fun dir ->
    Typescript_generator.Ts_generator.generate_typescript_sdk
      ~use_fallback_versions:true sample_spec dir;
    let ic = open_in (Filename.concat (Filename.concat dir "src") "index.ts") in
    let content = really_input_string ic (in_channel_length ic) in
    close_in ic;
    check_contains ~msg:"class in index.ts" content "class OAuth2Client"
  )

let test_contains_client_secret_config () =
  check_contains ~msg:"clientSecret in AuthConfig"
    (Lazy.force client_code) "clientSecret?: string"

let test_contains_runtime_url_config () =
  let code = Lazy.force client_code in
  check_contains ~msg:"authorizeUrl in AuthConfig" code "authorizeUrl?: string";
  check_contains ~msg:"tokenUrl in AuthConfig" code "tokenUrl?: string"

let test_contains_get_access_token () =
  check_contains ~msg:"getAccessToken method"
    (Lazy.force client_code) "getAccessToken"

let test_contains_expires_at () =
  check_contains ~msg:"expires_at tracking"
    (Lazy.force client_code) "expires_at"

let test_contains_introspect_token () =
  check_contains ~msg:"introspectToken method"
    (Lazy.force client_code) "introspectToken"

let test_contains_revoke_token () =
  check_contains ~msg:"revokeToken method"
    (Lazy.force client_code) "revokeToken"

let tests = [
  Alcotest.test_case "generated code contains OAuth2Client class" `Quick test_contains_class;
  Alcotest.test_case "generated code contains provider URLs" `Quick test_contains_provider_urls;
  Alcotest.test_case "generated code contains scopes" `Quick test_contains_scopes;
  Alcotest.test_case "generated code contains PKCE methods" `Quick test_contains_pkce_methods;
  Alcotest.test_case "generated code contains interfaces" `Quick test_contains_interfaces;
  Alcotest.test_case "generated code contains exchange/refresh" `Quick test_contains_exchange_refresh;
  Alcotest.test_case "generated code contains spec name" `Quick test_contains_spec_name;
  Alcotest.test_case "package.json has correct versions" `Quick test_package_json_versions;
  Alcotest.test_case "package.json is valid JSON" `Quick test_package_json_valid_json;
  Alcotest.test_case "package.json contains provider name" `Quick test_package_json_contains_name;
  Alcotest.test_case "tsconfig has strict mode" `Quick test_tsconfig_strict;
  Alcotest.test_case "SDK generation creates expected files" `Quick test_sdk_creates_files;
  Alcotest.test_case "SDK index.ts contains OAuth2Client" `Quick test_sdk_index_contains_class;
  Alcotest.test_case "AuthConfig has clientSecret field" `Quick test_contains_client_secret_config;
  Alcotest.test_case "AuthConfig has runtime URL fields" `Quick test_contains_runtime_url_config;
  Alcotest.test_case "generated code has getAccessToken" `Quick test_contains_get_access_token;
  Alcotest.test_case "generated code tracks expires_at" `Quick test_contains_expires_at;
  Alcotest.test_case "generated code has introspectToken" `Quick test_contains_introspect_token;
  Alcotest.test_case "generated code has revokeToken" `Quick test_contains_revoke_token;
]
