open Ast.Auth_types

let test_ast_pkce_defaults () =
  let p = create_provider "test" "id" "http://a" "http://t" [] in
  let spec = create_oauth2_spec "test" [p] in
  match spec.protocol with
  | OAuth2 config ->
      let pkce_testable = Alcotest.testable pp_pkce_method (=) in
      Alcotest.(check pkce_testable) "default is S256" S256 config.pkce_method

let test_ast_pkce_plain () =
  let p = create_provider "test" "id" "http://a" "http://t" [] in
  let spec = { (create_oauth2_spec "test" [p]) with 
    protocol = OAuth2 { flows = [AuthorizationCode]; pkce_method = Plain; state_required = true }
  } in
  match spec.protocol with
  | OAuth2 config ->
      let pkce_testable = Alcotest.testable pp_pkce_method (=) in
      Alcotest.(check pkce_testable) "is Plain" Plain config.pkce_method

let test_ast_pkce_none () =
  let p = create_provider "test" "id" "http://a" "http://t" [] in
  let spec = { (create_oauth2_spec "test" [p]) with 
    protocol = OAuth2 { flows = [AuthorizationCode]; pkce_method = NoPKCE; state_required = true }
  } in
  match spec.protocol with
  | OAuth2 config ->
      let pkce_testable = Alcotest.testable pp_pkce_method (=) in
      Alcotest.(check pkce_testable) "is NoPKCE" NoPKCE config.pkce_method

let test_ts_generator_pkce_s256 () =
  let p = create_provider "test" "id" "http://a" "http://t" [] in
  let spec = create_oauth2_spec "test" [p] in
  let code = Typescript_generator.Ts_generator.generate_oauth2_client spec p in
  let contains sub = 
    let re = Str.regexp_string sub in
    try ignore (Str.search_forward re code 0); true with Not_found -> false
  in
  Alcotest.(check bool) "contains PKCE verifier" true (contains "generateCodeVerifier");
  Alcotest.(check bool) "contains S256 challenge" true (contains "SHA-256")

let test_ts_generator_pkce_none () =
  let p = create_provider "test" "id" "http://a" "http://t" [] in
  let spec = { (create_oauth2_spec "test" [p]) with 
    protocol = OAuth2 { flows = [AuthorizationCode]; pkce_method = NoPKCE; state_required = true }
  } in
  let code = Typescript_generator.Ts_generator.generate_oauth2_client spec p in
  let contains sub = 
    let re = Str.regexp_string sub in
    try ignore (Str.search_forward re code 0); true with Not_found -> false
  in
  Alcotest.(check bool) "does not contain generateCodeVerifier" false (contains "generateCodeVerifier");
  Alcotest.(check bool) "does not contain S256 challenge" false (contains "SHA-256")

let tests = [
  Alcotest.test_case "AST default PKCE method" `Quick test_ast_pkce_defaults;
  Alcotest.test_case "AST Plain PKCE method" `Quick test_ast_pkce_plain;
  Alcotest.test_case "AST None PKCE method" `Quick test_ast_pkce_none;
  Alcotest.test_case "TS Generator S256 PKCE" `Quick test_ts_generator_pkce_s256;
  Alcotest.test_case "TS Generator None PKCE" `Quick test_ts_generator_pkce_none;
]
