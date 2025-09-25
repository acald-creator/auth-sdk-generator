let usage_msg = "auth-sdk-generator [OPTIONS] <spec-file> <output-dir>"
let spec_file = ref ""
let output_dir = ref ""
let use_fallback_versions = ref false
let validate_code = ref true
let target_language = ref "typescript"

let set_spec_file filename = spec_file := filename
let set_output_dir dirname = output_dir := dirname
let set_language lang = target_language := lang

let spec = [
  ("-v", Arg.Unit (fun () -> print_endline "Auth SDK Generator v1.0.0-prototype"), " Show version");
  ("--lang", Arg.String set_language, " Target language (typescript|python, default: typescript)");
  ("--language", Arg.String set_language, " Target language (typescript|python, default: typescript)");
  ("--offline", Arg.Set use_fallback_versions, " Use fallback versions instead of fetching latest");
  ("--fallback-versions", Arg.Set use_fallback_versions, " Use fallback versions instead of fetching latest");
  ("--validate", Arg.Set validate_code, " Enable code validation (default: true)");
  ("--no-validate", Arg.Clear validate_code, " Disable code validation");
]

let () =
  Arg.parse spec (fun arg ->
    if !spec_file = "" then set_spec_file arg
    else if !output_dir = "" then set_output_dir arg
    else raise (Arg.Bad "Too many arguments")
  ) usage_msg;

  if !spec_file = "" || !output_dir = "" then (
    Arg.usage spec usage_msg;
    exit 1
  );

  try
    Printf.printf "🔨 Parsing specification: %s\n" !spec_file;
    let spec = Parsers.Simple_parser.parse_file !spec_file in

    let language_name = match String.lowercase_ascii !target_language with
      | "typescript" | "ts" -> "TypeScript"
      | "python" | "py" -> "Python"
      | _ -> Printf.eprintf "❌ Unsupported language: %s\n" !target_language;
             Printf.eprintf "   Supported languages: typescript, python\n";
             exit 1 in

    Printf.printf "📦 Generating %s SDK...\n" language_name;
    Printf.printf "   Name: %s\n" spec.name;
    Printf.printf "   Providers: %d\n" (List.length spec.providers);
    Printf.printf "   Validation: %s\n" (if !validate_code then "enabled" else "disabled");

    let provider = List.hd spec.providers in

    if !validate_code then (
      match String.lowercase_ascii !target_language with
      | "typescript" | "ts" ->
          Validators.Typescript_validator.validate_generated_client spec provider
      | "python" | "py" ->
          Validators.Python_validator.validate_generated_client spec provider
      | _ -> () (* Already handled above *)
    );

    (match String.lowercase_ascii !target_language with
    | "typescript" | "ts" ->
        Typescript_generator.Ts_generator.generate_typescript_sdk ~use_fallback_versions:!use_fallback_versions spec !output_dir;
        Printf.printf "🚀 Next steps:\n";
        Printf.printf "   cd %s\n" !output_dir;
        Printf.printf "   npm install\n";
        Printf.printf "   npm run build\n"
    | "python" | "py" ->
        Python_generator.Py_generator.generate_python_sdk spec !output_dir;
        Printf.printf "🚀 Next steps:\n";
        Printf.printf "   cd %s\n" !output_dir;
        Printf.printf "   pip install -e .\n";
        Printf.printf "   python -c \"from auth_sdk import OAuth2Client; print('✅ Import successful')\"\n"
    | _ -> () (* Already handled above *)
    );

  with
  | Sys_error msg -> Printf.eprintf "❌ Error: %s\n" msg; exit 1
  | Parsers.Simple_parser.Parse_error msg -> Printf.eprintf "❌ Parse error: %s\n" msg; exit 1
  | Validators.Typescript_validator.Validation_error msg -> Printf.eprintf "❌ Validation error: %s\n" msg; exit 1
  | Validators.Python_validator.Validation_error msg -> Printf.eprintf "❌ Python validation error: %s\n" msg; exit 1
  | exn -> Printf.eprintf "❌ Unexpected error: %s\n" (Printexc.to_string exn); exit 1
