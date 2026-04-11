open Ast.Auth_types

(* --- Test fixtures --- *)

let sample_provider =
  create_provider
    "TestProvider"
    "test-client-123"
    "https://auth.example.com/authorize"
    "https://auth.example.com/token"
    ["read"; "write"]

let sample_spec = create_oauth2_spec "Test App" [sample_provider]

let github_provider =
  create_provider
    "GitHub"
    "gh-client-id"
    "https://github.com/login/oauth/authorize"
    "https://github.com/login/oauth/access_token"
    ["read:user"; "user:email"]

let github_spec = create_oauth2_spec "GitHub Integration" [github_provider]

let stripe_provider = {
  name = "StripeConnect";
  client_id = "ca_test123";
  client_secret = Some "sk_test_secret";
  authorize_url = "https://connect.stripe.com/oauth/authorize";
  token_url = "https://connect.stripe.com/oauth/token";
  scopes = ["read_write"];
  extra_params = [];
}

let stripe_spec = create_oauth2_spec "Stripe Connect" [stripe_provider]

let stripe_dsl = {|
name = "Stripe Connect"
client_id = "ca_test123"
client_secret = "sk_test_secret"
authorize_url = "https://connect.stripe.com/oauth/authorize"
token_url = "https://connect.stripe.com/oauth/token"
scopes = "read_write"
|}

let minimal_dsl = {|
client_id = "test-client-123"
|}

let full_dsl = {|
name = "Test App"
client_id = "test-client-123"
authorize_url = "https://auth.example.com/authorize"
token_url = "https://auth.example.com/token"
scopes = "read,write"
|}

let github_dsl = {|
name = "GitHub Integration"
client_id = "gh-client-id"
authorize_url = "https://github.com/login/oauth/authorize"
token_url = "https://github.com/login/oauth/access_token"
scopes = "read:user,user:email"
|}

(* --- Utilities --- *)

let contains_substring s sub =
  try
    let _ = Str.search_forward (Str.regexp_string sub) s 0 in
    true
  with Not_found -> false

let check_contains ~msg s sub =
  Alcotest.(check bool) msg true (contains_substring s sub)

let has_command cmd =
  Sys.command (Printf.sprintf "which %s >/dev/null 2>&1" cmd) = 0

let make_temp_dir () =
  let dir = Filename.temp_file "auth_sdk_test" "" in
  Sys.remove dir;
  Unix.mkdir dir 0o755;
  dir

let rec remove_dir_recursive dir =
  if Sys.file_exists dir then (
    let files = Sys.readdir dir in
    Array.iter (fun file ->
      let path = Filename.concat dir file in
      if Sys.is_directory path then
        remove_dir_recursive path
      else
        Sys.remove path
    ) files;
    Unix.rmdir dir
  )

let with_temp_dir f =
  let dir = make_temp_dir () in
  Fun.protect ~finally:(fun () -> remove_dir_recursive dir) (fun () -> f dir)
