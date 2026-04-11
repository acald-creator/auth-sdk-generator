open Ast.Auth_types

let provider_testable =
  Alcotest.testable pp_provider (=)

let test_create_provider_fields () =
  let p = create_provider "github" "cid" "https://a" "https://t" ["read"] in
  Alcotest.(check string) "name" "github" p.name;
  Alcotest.(check string) "client_id" "cid" p.client_id;
  Alcotest.(check (option string)) "client_secret" None p.client_secret;
  Alcotest.(check string) "authorize_url" "https://a" p.authorize_url;
  Alcotest.(check string) "token_url" "https://t" p.token_url;
  Alcotest.(check (list string)) "scopes" ["read"] p.scopes;
  Alcotest.(check (list (pair string string))) "extra_params" [] p.extra_params

let test_create_provider_empty_scopes () =
  let p = create_provider "test" "id" "https://a" "https://t" [] in
  Alcotest.(check (list string)) "scopes" [] p.scopes

let test_create_provider_multiple_scopes () =
  let p = create_provider "test" "id" "https://a" "https://t" ["a"; "b"; "c"] in
  Alcotest.(check (list string)) "scopes" ["a"; "b"; "c"] p.scopes

let test_create_oauth2_spec_defaults () =
  let p = create_provider "test" "id" "https://a" "https://t" [] in
  let spec = create_oauth2_spec "myapp" [p] in
  Alcotest.(check string) "name" "myapp" spec.name;
  match spec.protocol with
  | OAuth2 config ->
    Alcotest.(check bool) "pkce" true config.pkce;
    Alcotest.(check bool) "state_required" true config.state_required;
    Alcotest.(check int) "flows count" 1 (List.length config.flows);
    Alcotest.(check bool) "is AuthorizationCode"
      true (List.hd config.flows = AuthorizationCode)

let test_create_oauth2_spec_preserves_providers () =
  let p1 = create_provider "p1" "id1" "https://a" "https://t" [] in
  let p2 = create_provider "p2" "id2" "https://a" "https://t" [] in
  let spec = create_oauth2_spec "multi" [p1; p2] in
  Alcotest.(check int) "provider count" 2 (List.length spec.providers);
  let names = List.map (fun p -> p.name) spec.providers in
  Alcotest.(check (list string)) "provider names" ["p1"; "p2"] names

let test_create_oauth2_spec_empty_providers () =
  let spec = create_oauth2_spec "empty" [] in
  Alcotest.(check int) "provider count" 0 (List.length spec.providers)

let test_show_provider_nonempty () =
  let p = create_provider "test" "id" "https://a" "https://t" ["read"] in
  let s = show_provider p in
  Alcotest.(check bool) "show is non-empty" true (String.length s > 0)

let tests = [
  Alcotest.test_case "create_provider sets all fields" `Quick test_create_provider_fields;
  Alcotest.test_case "create_provider with empty scopes" `Quick test_create_provider_empty_scopes;
  Alcotest.test_case "create_provider with multiple scopes" `Quick test_create_provider_multiple_scopes;
  Alcotest.test_case "create_oauth2_spec sets defaults" `Quick test_create_oauth2_spec_defaults;
  Alcotest.test_case "create_oauth2_spec preserves providers" `Quick test_create_oauth2_spec_preserves_providers;
  Alcotest.test_case "create_oauth2_spec with empty providers" `Quick test_create_oauth2_spec_empty_providers;
  Alcotest.test_case "show_provider produces non-empty string" `Quick test_show_provider_nonempty;
]
