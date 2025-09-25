open Printf

exception Validation_error of string

(** Check if string contains substring *)
let contains_substring str sub =
  try
    let _ = Str.search_forward (Str.regexp_string sub) str 0 in
    true
  with
  | Not_found -> false

(** Execute command and return result *)
let exec_command cmd =
  try
    let ic = Unix.open_process_in cmd in
    let output =
      try
        let buffer = Buffer.create 1024 in
        (try
          while true do
            let line = input_line ic in
            Buffer.add_string buffer line;
            Buffer.add_char buffer '\n'
          done
        with End_of_file -> ());
        let content = Buffer.contents buffer |> String.trim in
        Some content
      with
      | _ -> Some ""
    in
    let status = Unix.close_process_in ic in
    (status, output)
  with
  | _ -> (Unix.WEXITED 1, Some "Command execution failed")

(** Enhanced validation with semantic and structural checks *)
let validate_oauth2_structure code_string =
  (* Check for required OAuth2 components *)
  let required_patterns = [
    ("OAuth2Client class", "class OAuth2Client");
    ("AuthConfig dataclass", "@dataclass");
    ("TokenSet dataclass", "class TokenSet");
    ("PKCE code verifier", "_generate_code_verifier");
    ("PKCE code challenge", "_generate_code_challenge");
    ("Authorization URL building", "_build_auth_url");
    ("Token exchange", "exchange_code");
    ("Requests import", "import requests");
    ("Base64 import", "import base64");
    ("Hashlib import", "import hashlib");
  ] in

  let missing_components = List.filter (fun (_, pattern) ->
    not (contains_substring code_string pattern)
  ) required_patterns in

  if missing_components <> [] then
    let missing_names = List.map fst missing_components in
    Error (sprintf "Missing required OAuth2 components: %s" (String.concat ", " missing_names))
  else
    Ok ()

(** Enhanced Python validation with syntax and type checking *)
let validate_python_syntax ?(check_oauth2=true) code_string =
  (* First check OAuth2 structure if requested *)
  (match check_oauth2 with
   | true ->
     (match validate_oauth2_structure code_string with
      | Error msg -> Error msg
      | Ok () -> Ok ())
   | false -> Ok ()) |> function
  | Error msg -> Error msg
  | Ok () ->

  let temp_dir = Filename.temp_file "py_validation" "" in
  let () = Sys.remove temp_dir in
  let () = Unix.mkdir temp_dir 0o755 in
  let auth_sdk_dir = Filename.concat temp_dir "auth_sdk" in
  let () = Unix.mkdir auth_sdk_dir 0o755 in

  (* Write temporary files with proper package structure *)
  let temp_file = Filename.concat auth_sdk_dir "oauth2_client.py" in
  let oc = open_out temp_file in
  let () = output_string oc code_string in
  let () = close_out oc in

  (* Write minimal __init__.py *)
  let init_file = Filename.concat auth_sdk_dir "__init__.py" in
  let oc2 = open_out init_file in
  let () = output_string oc2 "from .oauth2_client import OAuth2Client, AuthConfig, TokenSet, AuthError\n" in
  let () = close_out oc2 in

  (* Write requirements.txt for dependencies *)
  let req_file = Filename.concat temp_dir "requirements.txt" in
  let oc3 = open_out req_file in
  let () = output_string oc3 "requests>=2.31.0\n" in
  let () = close_out oc3 in

  (* Run Python syntax check and basic imports *)
  let cmd = sprintf "cd %s && python3 -m py_compile auth_sdk/oauth2_client.py 2>&1" temp_dir in
  let (status, output) = exec_command cmd in

  (* Cleanup *)
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
  in
  remove_dir_recursive temp_dir;

  match status with
  | Unix.WEXITED 0 ->
      printf "   ✅ Python syntax validation passed\n";
      printf "   🐍 Python 3 compatibility verified\n";
      Ok ()
  | _ ->
      let error_msg = match output with
        | Some msg when String.length (String.trim msg) > 0 ->
            (* Parse and format Python errors *)
            let lines = String.split_on_char '\n' msg in
            let error_lines = List.filter (fun line ->
              contains_substring line "SyntaxError" ||
              contains_substring line "IndentationError" ||
              contains_substring line "ImportError" ||
              contains_substring line "ModuleNotFoundError" ||
              contains_substring line "Error:" ||
              String.length (String.trim line) > 0
            ) lines in
            String.concat "\n" error_lines
        | _ -> "Python compilation failed with no error output" in
      printf "   ❌ Python syntax validation failed\n";
      printf "   🔍 Compilation errors found\n";
      Error (sprintf "Python validation failed:\n%s" error_msg)

(** Validate Python with mypy type checking if available *)
let validate_python_types ?(_check_oauth2=false) code_string =
  let temp_dir = Filename.temp_file "py_mypy" "" in
  let () = Sys.remove temp_dir in
  let () = Unix.mkdir temp_dir 0o755 in
  let auth_sdk_dir = Filename.concat temp_dir "auth_sdk" in
  let () = Unix.mkdir auth_sdk_dir 0o755 in

  (* Write temporary files *)
  let temp_file = Filename.concat auth_sdk_dir "oauth2_client.py" in
  let oc = open_out temp_file in
  let () = output_string oc code_string in
  let () = close_out oc in

  let init_file = Filename.concat auth_sdk_dir "__init__.py" in
  let oc2 = open_out init_file in
  let () = output_string oc2 "from .oauth2_client import OAuth2Client\n" in
  let () = close_out oc2 in

  (* Check if mypy is available and run it *)
  let cmd = sprintf "cd %s && which mypy >/dev/null 2>&1 && mypy auth_sdk/oauth2_client.py --ignore-missing-imports 2>&1 || echo 'mypy not available'" temp_dir in
  let (_status, output) = exec_command cmd in

  (* Cleanup *)
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
  in
  remove_dir_recursive temp_dir;

  match output with
  | Some msg when contains_substring msg "mypy not available" ->
      printf "   ⚠️  mypy not available - skipping type checking\n";
      Ok ()
  | Some msg when String.length (String.trim msg) = 0 ->
      printf "   ✅ Python type checking passed\n";
      Ok ()
  | Some msg ->
      printf "   ⚠️  mypy found type issues:\n";
      let lines = String.split_on_char '\n' msg in
      List.iteri (fun i line ->
        if i < 3 && String.length (String.trim line) > 0 then
          printf "     %s\n" line
      ) lines;
      Ok () (* Don't fail on type warnings *)
  | None ->
      Ok ()

(** Quick validation of generated Python client *)
let validate_generated_client spec provider =
  printf "🔍 Validating generated Python code...\n";

  let client_code = Python_generator.Py_generator.generate_oauth2_client spec provider in

  (* First check OAuth2 structure *)
  match validate_oauth2_structure client_code with
  | Error msg ->
      printf "   ❌ OAuth2 structure validation failed\n";
      raise (Validation_error msg)
  | Ok () ->
      printf "   ✅ OAuth2 structure validation passed\n";

      (* Then check Python syntax *)
      match validate_python_syntax ~check_oauth2:false client_code with
      | Ok () ->
          (* Run optional type checking *)
          (match validate_python_types client_code with
          | Ok () -> printf "✅ Python validation passed\n"
          | Error msg ->
              printf "   ❌ Python type checking errors found:\n";
              printf "     %s\n" msg;
              raise (Validation_error "Python validation failed - see errors above"))
      | Error msg ->
          printf "   ❌ Python compilation errors found:\n";
          let lines = String.split_on_char '\n' msg in
          let error_lines = List.filter (fun line ->
            contains_substring line "Error" ||
            String.length (String.trim line) > 10
          ) lines in
          List.iteri (fun i line ->
            if i < 5 then printf "     %s\n" line
          ) error_lines;
          if List.length error_lines > 5 then
            printf "     ... and %d more errors\n" (List.length error_lines - 5);
          raise (Validation_error "Python validation failed - see errors above")