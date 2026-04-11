open Test_helpers

(* --- TypeScript validator structure checks --- *)

let test_ts_structure_valid () =
  let code = Typescript_generator.Ts_generator.generate_oauth2_client
    sample_spec sample_provider in
  match Validators.Typescript_validator.validate_oauth2_structure code with
  | Ok () -> Alcotest.(check pass) "valid TS structure" () ()
  | Error msg -> Alcotest.fail msg

let test_ts_structure_empty_fails () =
  match Validators.Typescript_validator.validate_oauth2_structure "" with
  | Ok () -> Alcotest.fail "expected Error for empty string"
  | Error msg ->
    check_contains ~msg:"lists missing components" msg "OAuth2Client class";
    check_contains ~msg:"lists AuthConfig" msg "AuthConfig interface"

let test_ts_structure_partial_fails () =
  match Validators.Typescript_validator.validate_oauth2_structure "class OAuth2Client {}" with
  | Ok () -> Alcotest.fail "expected Error for partial code"
  | Error msg ->
    check_contains ~msg:"lists missing" msg "AuthConfig interface"

(* --- Python validator structure checks --- *)

let test_py_structure_valid () =
  let code = Python_generator.Py_generator.generate_oauth2_client
    sample_spec sample_provider in
  match Validators.Python_validator.validate_oauth2_structure code with
  | Ok () -> Alcotest.(check pass) "valid PY structure" () ()
  | Error msg -> Alcotest.fail msg

let test_py_structure_empty_fails () =
  match Validators.Python_validator.validate_oauth2_structure "" with
  | Ok () -> Alcotest.fail "expected Error for empty string"
  | Error msg ->
    check_contains ~msg:"lists missing" msg "OAuth2Client class"

let test_py_structure_partial_fails () =
  match Validators.Python_validator.validate_oauth2_structure "class OAuth2Client:" with
  | Ok () -> Alcotest.fail "expected Error for partial code"
  | Error msg ->
    check_contains ~msg:"lists missing imports" msg "Requests import"

(* --- Conditional external tool tests --- *)

let test_ts_syntax_valid () =
  if not (has_command "tsc") then
    Alcotest.(check pass) "skipped - tsc not found" () ()
  else
    let code = Typescript_generator.Ts_generator.generate_oauth2_client
      sample_spec sample_provider in
    match Validators.Typescript_validator.validate_typescript_syntax ~check_oauth2:false code with
    | Ok () -> Alcotest.(check pass) "tsc passed" () ()
    | Error msg -> Alcotest.fail msg

let test_py_syntax_valid () =
  if not (has_command "python3") then
    Alcotest.(check pass) "skipped - python3 not found" () ()
  else
    let code = Python_generator.Py_generator.generate_oauth2_client
      sample_spec sample_provider in
    match Validators.Python_validator.validate_python_syntax ~check_oauth2:false code with
    | Ok () -> Alcotest.(check pass) "python3 passed" () ()
    | Error msg -> Alcotest.fail msg

let tests = [
  Alcotest.test_case "TS structure: valid code passes" `Quick test_ts_structure_valid;
  Alcotest.test_case "TS structure: empty string fails" `Quick test_ts_structure_empty_fails;
  Alcotest.test_case "TS structure: partial code fails" `Quick test_ts_structure_partial_fails;
  Alcotest.test_case "PY structure: valid code passes" `Quick test_py_structure_valid;
  Alcotest.test_case "PY structure: empty string fails" `Quick test_py_structure_empty_fails;
  Alcotest.test_case "PY structure: partial code fails" `Quick test_py_structure_partial_fails;
  Alcotest.test_case "TS syntax: generated code compiles" `Slow test_ts_syntax_valid;
  Alcotest.test_case "PY syntax: generated code compiles" `Slow test_py_syntax_valid;
]
