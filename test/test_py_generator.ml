open Test_helpers

let client_code =
  lazy (Python_generator.Py_generator.generate_oauth2_client sample_spec sample_provider)

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
  check_contains ~msg:"_generate_code_verifier" code "_generate_code_verifier";
  check_contains ~msg:"_generate_code_challenge" code "_generate_code_challenge"

let test_contains_imports () =
  let code = Lazy.force client_code in
  check_contains ~msg:"import base64" code "import base64";
  check_contains ~msg:"import hashlib" code "import hashlib";
  check_contains ~msg:"import requests" code "import requests"

let test_contains_dataclasses () =
  let code = Lazy.force client_code in
  check_contains ~msg:"@dataclass" code "@dataclass";
  check_contains ~msg:"class AuthConfig" code "class AuthConfig";
  check_contains ~msg:"class TokenSet" code "class TokenSet"

let test_contains_auth_error () =
  check_contains ~msg:"AuthError"
    (Lazy.force client_code) "class AuthError(Exception)"

let test_contains_exchange_refresh () =
  let code = Lazy.force client_code in
  check_contains ~msg:"exchange_code" code "async def exchange_code";
  check_contains ~msg:"refresh_token" code "async def refresh_token"

let test_sdk_creates_files () =
  with_temp_dir (fun dir ->
    Python_generator.Py_generator.generate_python_sdk sample_spec dir;
    let auth_sdk = Filename.concat dir "auth_sdk" in
    Alcotest.(check bool) "oauth2_client.py exists" true
      (Sys.file_exists (Filename.concat auth_sdk "oauth2_client.py"));
    Alcotest.(check bool) "__init__.py exists" true
      (Sys.file_exists (Filename.concat auth_sdk "__init__.py"));
    Alcotest.(check bool) "setup.py exists" true
      (Sys.file_exists (Filename.concat dir "setup.py"));
    Alcotest.(check bool) "requirements.txt exists" true
      (Sys.file_exists (Filename.concat dir "requirements.txt"));
    Alcotest.(check bool) "README.md exists" true
      (Sys.file_exists (Filename.concat dir "README.md"));
    Alcotest.(check bool) "pytest.ini exists" true
      (Sys.file_exists (Filename.concat dir "pytest.ini"));
    Alcotest.(check bool) "mypy.ini exists" true
      (Sys.file_exists (Filename.concat dir "mypy.ini"))
  )

let test_setup_py_contains_name () =
  with_temp_dir (fun dir ->
    Python_generator.Py_generator.generate_python_sdk sample_spec dir;
    let ic = open_in (Filename.concat dir "setup.py") in
    let content = really_input_string ic (in_channel_length ic) in
    close_in ic;
    check_contains ~msg:"provider name" content "testprovider-auth-sdk"
  )

let test_requirements_contains_requests () =
  let req = Python_generator.Py_generator.generate_requirements () in
  check_contains ~msg:"requests" req "requests>=2.31.0"

let test_contains_client_secret_config () =
  check_contains ~msg:"client_secret in AuthConfig"
    (Lazy.force client_code) "client_secret: Optional[str]"

let test_contains_runtime_url_config () =
  let code = Lazy.force client_code in
  check_contains ~msg:"authorize_url in AuthConfig" code "authorize_url: Optional[str]";
  check_contains ~msg:"token_url in AuthConfig" code "token_url: Optional[str]"

let test_contains_get_access_token () =
  check_contains ~msg:"get_access_token method"
    (Lazy.force client_code) "get_access_token"

let test_contains_time_import () =
  check_contains ~msg:"import time"
    (Lazy.force client_code) "import time"

let tests = [
  Alcotest.test_case "generated code contains OAuth2Client class" `Quick test_contains_class;
  Alcotest.test_case "generated code contains provider URLs" `Quick test_contains_provider_urls;
  Alcotest.test_case "generated code contains scopes" `Quick test_contains_scopes;
  Alcotest.test_case "generated code contains PKCE methods" `Quick test_contains_pkce_methods;
  Alcotest.test_case "generated code contains imports" `Quick test_contains_imports;
  Alcotest.test_case "generated code contains dataclasses" `Quick test_contains_dataclasses;
  Alcotest.test_case "generated code contains AuthError" `Quick test_contains_auth_error;
  Alcotest.test_case "generated code contains exchange/refresh" `Quick test_contains_exchange_refresh;
  Alcotest.test_case "SDK generation creates expected files" `Quick test_sdk_creates_files;
  Alcotest.test_case "setup.py contains provider name" `Quick test_setup_py_contains_name;
  Alcotest.test_case "requirements.txt contains requests" `Quick test_requirements_contains_requests;
  Alcotest.test_case "AuthConfig has client_secret field" `Quick test_contains_client_secret_config;
  Alcotest.test_case "AuthConfig has runtime URL fields" `Quick test_contains_runtime_url_config;
  Alcotest.test_case "generated code has get_access_token" `Quick test_contains_get_access_token;
  Alcotest.test_case "generated code imports time" `Quick test_contains_time_import;
]
