open Ast.Auth_types

let test_parse_minimal_input () =
  let spec = Parsers.Simple_parser.parse_simple_dsl {|client_id = "abc"|} in
  Alcotest.(check string) "default name" "prototype" spec.name;
  let p = List.hd spec.providers in
  Alcotest.(check string) "client_id" "abc" p.client_id;
  Alcotest.(check string) "default authorize_url"
    "https://accounts.google.com/o/oauth2/v2/auth" p.authorize_url;
  Alcotest.(check string) "default token_url"
    "https://oauth2.googleapis.com/token" p.token_url;
  Alcotest.(check (list string)) "empty scopes" [] p.scopes

let test_parse_fully_specified () =
  let spec = Parsers.Simple_parser.parse_simple_dsl Test_helpers.full_dsl in
  Alcotest.(check string) "name" "Test App" spec.name;
  let p = List.hd spec.providers in
  Alcotest.(check string) "client_id" "test-client-123" p.client_id;
  Alcotest.(check string) "authorize_url" "https://auth.example.com/authorize" p.authorize_url;
  Alcotest.(check string) "token_url" "https://auth.example.com/token" p.token_url;
  Alcotest.(check (list string)) "scopes" ["read"; "write"] p.scopes

let test_parse_quoted_values () =
  let spec = Parsers.Simple_parser.parse_simple_dsl {|client_id = "my-id"|} in
  let p = List.hd spec.providers in
  Alcotest.(check string) "quotes stripped" "my-id" p.client_id

let test_parse_unquoted_values () =
  let spec = Parsers.Simple_parser.parse_simple_dsl {|client_id = my-id|} in
  let p = List.hd spec.providers in
  Alcotest.(check string) "unquoted works" "my-id" p.client_id

let test_parse_skips_comments () =
  let input = {|
# This is a comment
client_id = "abc"
# Another comment
name = "Commented App"
|} in
  let spec = Parsers.Simple_parser.parse_simple_dsl input in
  Alcotest.(check string) "name" "Commented App" spec.name;
  let p = List.hd spec.providers in
  Alcotest.(check string) "client_id" "abc" p.client_id

let test_parse_skips_blank_lines () =
  let input = {|

client_id = "abc"

name = "Spaced App"

|} in
  let spec = Parsers.Simple_parser.parse_simple_dsl input in
  Alcotest.(check string) "name" "Spaced App" spec.name

let test_parse_scopes_comma_separated () =
  let input = {|
client_id = "abc"
scopes = "openid,email,profile"
|} in
  let spec = Parsers.Simple_parser.parse_simple_dsl input in
  let p = List.hd spec.providers in
  Alcotest.(check (list string)) "scopes" ["openid"; "email"; "profile"] p.scopes

let test_parse_scopes_with_spaces () =
  let input = {|
client_id = "abc"
scopes = "read, write, admin"
|} in
  let spec = Parsers.Simple_parser.parse_simple_dsl input in
  let p = List.hd spec.providers in
  Alcotest.(check (list string)) "spaces trimmed" ["read"; "write"; "admin"] p.scopes

let test_parse_missing_client_id_raises () =
  Alcotest.check_raises "missing client_id"
    (Parsers.Simple_parser.Parse_error "client_id is required")
    (fun () -> ignore (Parsers.Simple_parser.parse_simple_dsl {|name = "No ID"|}))

let test_parse_empty_client_id_raises () =
  Alcotest.check_raises "empty client_id"
    (Parsers.Simple_parser.Parse_error "client_id is required")
    (fun () -> ignore (Parsers.Simple_parser.parse_simple_dsl {|client_id = ""|}))

let test_parse_lines_without_equals_ignored () =
  let input = {|
client_id = "abc"
this is not a key-value pair
name = "Still Works"
|} in
  let spec = Parsers.Simple_parser.parse_simple_dsl input in
  Alcotest.(check string) "name" "Still Works" spec.name

let test_parse_duplicate_keys_last_wins () =
  let input = {|
client_id = "abc"
name = "First"
name = "Second"
|} in
  let spec = Parsers.Simple_parser.parse_simple_dsl input in
  (* parse_lines prepends with cons, List.assoc_opt finds first match = last input line *)
  Alcotest.(check string) "last value wins" "Second" spec.name

let test_parse_always_produces_authcode_pkce () =
  let spec = Parsers.Simple_parser.parse_simple_dsl {|client_id = "abc"|} in
  match spec.protocol with
  | OAuth2 config ->
    Alcotest.(check bool) "pkce" true config.pkce;
    Alcotest.(check bool) "state_required" true config.state_required;
    Alcotest.(check int) "one flow" 1 (List.length config.flows);
    Alcotest.(check bool) "AuthorizationCode" true
      (List.hd config.flows = AuthorizationCode)

let test_parse_file () =
  (* Write a temp .auth file and parse it to test file I/O *)
  let tmp = Filename.temp_file "test_spec" ".auth" in
  Fun.protect ~finally:(fun () -> Sys.remove tmp) (fun () ->
    let oc = open_out tmp in
    output_string oc Test_helpers.full_dsl;
    close_out oc;
    let spec = Parsers.Simple_parser.parse_file tmp in
    Alcotest.(check string) "name" "Test App" spec.name;
    let p = List.hd spec.providers in
    Alcotest.(check (list string)) "scopes" ["read"; "write"] p.scopes
  )

let tests = [
  Alcotest.test_case "parse minimal input" `Quick test_parse_minimal_input;
  Alcotest.test_case "parse fully specified input" `Quick test_parse_fully_specified;
  Alcotest.test_case "parse quoted values" `Quick test_parse_quoted_values;
  Alcotest.test_case "parse unquoted values" `Quick test_parse_unquoted_values;
  Alcotest.test_case "parse skips comments" `Quick test_parse_skips_comments;
  Alcotest.test_case "parse skips blank lines" `Quick test_parse_skips_blank_lines;
  Alcotest.test_case "parse scopes comma-separated" `Quick test_parse_scopes_comma_separated;
  Alcotest.test_case "parse scopes with spaces" `Quick test_parse_scopes_with_spaces;
  Alcotest.test_case "parse missing client_id raises" `Quick test_parse_missing_client_id_raises;
  Alcotest.test_case "parse empty client_id raises" `Quick test_parse_empty_client_id_raises;
  Alcotest.test_case "parse lines without = ignored" `Quick test_parse_lines_without_equals_ignored;
  Alcotest.test_case "parse duplicate keys last wins" `Quick test_parse_duplicate_keys_last_wins;
  Alcotest.test_case "parse always produces AuthCode+PKCE" `Quick test_parse_always_produces_authcode_pkce;
  Alcotest.test_case "parse_file reads specs/prototype.auth" `Quick test_parse_file;
]
