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
    ("AuthConfig interface", "interface AuthConfig");
    ("TokenSet interface", "interface TokenSet");
    ("PKCE code verifier", "generateCodeVerifier");
    ("PKCE code challenge", "generateCodeChallenge");
    ("Authorization URL building", "buildAuthUrl");
    ("Token exchange", "exchangeCode");
  ] in

  let missing_components = List.filter (fun (_, pattern) ->
    not (contains_substring code_string pattern)
  ) required_patterns in

  if missing_components <> [] then
    let missing_names = List.map fst missing_components in
    Error (sprintf "Missing required OAuth2 components: %s" (String.concat ", " missing_names))
  else
    Ok ()

(** Enhanced TypeScript validation with detailed error reporting *)
let validate_typescript_syntax ?(check_oauth2=true) code_string =
  (* First check OAuth2 structure if requested *)
  (match check_oauth2 with
   | true ->
     (match validate_oauth2_structure code_string with
      | Error msg -> Error msg
      | Ok () -> Ok ())
   | false -> Ok ()) |> function
  | Error msg -> Error msg
  | Ok () ->

  let temp_dir = Filename.temp_file "ts_validation" "" in
  let () = Sys.remove temp_dir in
  let () = Unix.mkdir temp_dir 0o755 in
  let src_dir = Filename.concat temp_dir "src" in
  let () = Unix.mkdir src_dir 0o755 in

  (* Write temporary files with proper project structure *)
  let temp_file = Filename.concat src_dir "index.ts" in
  let oc = open_out temp_file in
  let () = output_string oc code_string in
  let () = close_out oc in

  (* Enhanced tsconfig.json with stricter checks *)
  let tsconfig_content = {|{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020", "DOM"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}|} in
  let tsconfig_file = Filename.concat temp_dir "tsconfig.json" in
  let oc2 = open_out tsconfig_file in
  let () = output_string oc2 tsconfig_content in
  let () = close_out oc2 in

  (* Run TypeScript compiler with enhanced reporting *)
  let cmd = sprintf "cd %s && tsc --noEmit --pretty 2>&1" temp_dir in
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
      printf "   ✅ TypeScript validation passed\n";
      printf "   📋 Strict type checking enabled\n";
      Ok ()
  | _ ->
      let error_msg = match output with
        | Some msg when String.length (String.trim msg) > 0 ->
            (* Parse and format TypeScript errors *)
            let lines = String.split_on_char '\n' msg in
            let error_lines = List.filter (fun line ->
              contains_substring line "error TS" ||
              contains_substring line "Error:" ||
              String.length (String.trim line) > 0
            ) lines in
            String.concat "\n" error_lines
        | _ -> "TypeScript compilation failed with no error output" in
      printf "   ❌ TypeScript validation failed\n";
      printf "   📊 Errors found during strict compilation\n";
      Error (sprintf "TypeScript validation failed:\n%s" error_msg)

(** Quick validation of generated client without writing to disk *)
let validate_generated_client spec provider =
  printf "🔍 Validating generated TypeScript code...\n";

  let client_code = Typescript_generator.Ts_generator.generate_oauth2_client spec provider in

  (* First check OAuth2 structure *)
  match validate_oauth2_structure client_code with
  | Error msg ->
      printf "   ❌ OAuth2 structure validation failed\n";
      raise (Validation_error msg)
  | Ok () ->
      printf "   ✅ OAuth2 structure validation passed\n";

      (* Then check TypeScript syntax *)
      match validate_typescript_syntax ~check_oauth2:false client_code with
      | Ok () ->
          printf "✅ TypeScript validation passed\n"
      | Error msg ->
          printf "   ❌ TypeScript compilation errors found:\n";
          (* Clean up ANSI color codes for cleaner error output *)
          let clean_msg = Str.global_replace (Str.regexp "\027\\[[0-9;]*m") "" msg in
          let lines = String.split_on_char '\n' clean_msg in
          let error_lines = List.filter (fun line ->
            contains_substring line "error TS" ||
            contains_substring line " - error" ||
            (contains_substring line ".ts:" && contains_substring line " - ")
          ) lines in
          List.iteri (fun i line ->
            if i < 5 then printf "     %s\n" line
          ) error_lines;
          if List.length error_lines > 5 then
            printf "     ... and %d more errors\n" (List.length error_lines - 5);
          raise (Validation_error "TypeScript validation failed - see errors above")