open Test_helpers

let client_code =
  lazy (Typescript_generator.Ts_generator.generate_oauth2_client sample_spec sample_provider)

let test_contains_client_class () =
  check_contains ~msg:"has TestAppClient class"
    (Lazy.force client_code) "class TestAppClient extends OAuthClient"

let test_contains_foundation_imports () =
  let code = Lazy.force client_code in
  check_contains ~msg:"foundation client import" code "from \"@cosmonexus/oauth-client\"";
  check_contains ~msg:"foundation react import" code "from \"@cosmonexus/oauth-react\""

let test_contains_provider_urls () =
  let code = Lazy.force client_code in
  check_contains ~msg:"issuerBaseUrl" code "issuerBaseUrl: \"https://auth.example.com\"";
  check_contains ~msg:"authorizePath" code "authorizePath: \"https://auth.example.com/authorize\"";
  check_contains ~msg:"tokenPath" code "tokenPath: \"https://auth.example.com/token\""

let test_contains_scopes () =
  let code = Lazy.force client_code in
  check_contains ~msg:"scopes list" code "scopes: [\"read\", \"write\"]"

let test_contains_react_components () =
  let code = Lazy.force client_code in
  check_contains ~msg:"Provider component" code "export function TestAppProvider";
  check_contains ~msg:"LoginButton component" code "export function TestAppLoginButton"

let test_contains_spec_name () =
  check_contains ~msg:"spec name in header"
    (Lazy.force client_code) "Test App"

let test_package_json_versions () =
  let json = Typescript_generator.Ts_generator.generate_package_json
    ~use_fallback_versions:true sample_provider in
  check_contains ~msg:"typescript version" json "\"typescript\": \"^5.9.2\"";
  check_contains ~msg:"@cosmonexus client" json "\"@cosmonexus/oauth-client\": \"workspace:*\""

let test_package_json_valid_json () =
  let json = Typescript_generator.Ts_generator.generate_package_json
    ~use_fallback_versions:true sample_provider in
  let _ = Yojson.Safe.from_string json in
  Alcotest.(check pass) "valid JSON" () ()

let test_tsconfig_jsx () =
  let config = Typescript_generator.Ts_generator.generate_tsconfig () in
  check_contains ~msg:"jsx" config "\"jsx\": \"react-jsx\""

let test_sdk_creates_files () =
  with_temp_dir (fun dir ->
    Typescript_generator.Ts_generator.generate_typescript_sdk
      ~use_fallback_versions:true sample_spec dir;
    Alcotest.(check bool) "src/index.ts exists" true
      (Sys.file_exists (Filename.concat (Filename.concat dir "src") "index.ts"));
    Alcotest.(check bool) "package.json exists" true
      (Sys.file_exists (Filename.concat dir "package.json"));
    Alcotest.(check bool) "README.md exists" true
      (Sys.file_exists (Filename.concat dir "README.md"))
  )

let tests = [
  Alcotest.test_case "generated code contains specialized client class" `Quick test_contains_client_class;
  Alcotest.test_case "generated code contains foundation imports" `Quick test_contains_foundation_imports;
  Alcotest.test_case "generated code contains provider URLs" `Quick test_contains_provider_urls;
  Alcotest.test_case "generated code contains scopes" `Quick test_contains_scopes;
  Alcotest.test_case "generated code contains React components" `Quick test_contains_react_components;
  Alcotest.test_case "generated code contains spec name" `Quick test_contains_spec_name;
  Alcotest.test_case "package.json has correct dependencies" `Quick test_package_json_versions;
  Alcotest.test_case "package.json is valid JSON" `Quick test_package_json_valid_json;
  Alcotest.test_case "tsconfig has JSX support" `Quick test_tsconfig_jsx;
  Alcotest.test_case "SDK generation creates expected files" `Quick test_sdk_creates_files;
]
