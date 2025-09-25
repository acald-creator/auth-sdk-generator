open Printf

(** Exception for version fetching errors *)
exception Version_fetch_error of string

(** Package version information *)
type package_version = {
  name: string;
  version: string;
  fetched_at: float;
}

(** Fallback versions for common packages (known working versions) *)
let fallback_versions = [
  ("typescript", "5.9.2");
  ("@types/node", "24.5.2");
  ("jest", "30.1.3");
  ("@types/jest", "30.0.0");
  ("ts-jest", "29.2.5");
]

(** Get fallback version for a package *)
let get_fallback_version package_name =
  match List.assoc_opt package_name fallback_versions with
  | Some version -> version
  | None -> "latest"

(** Execute command and return output if successful *)
let exec_command cmd =
  try
    let ic = Unix.open_process_in cmd in
    let output =
      try
        let content = input_line ic |> String.trim in
        Some content
      with
      | End_of_file -> None
      | _ -> None
    in
    let status = Unix.close_process_in ic in
    match status with
    | Unix.WEXITED 0 -> output
    | _ -> None
  with
  | _ -> None

(** Fetch latest version using npm show command *)
let fetch_latest_version_npm package_name =
  let cmd = sprintf "npm show %s version 2>/dev/null" package_name in
  exec_command cmd

(** Fetch latest version using curl to npm registry *)
let fetch_latest_version_curl package_name =
  try
    let escaped_name = String.map (function '@' -> '%' | '/' -> '%' | c -> c) package_name in
    let url = sprintf "https://registry.npmjs.org/%s/latest" escaped_name in
    let cmd = sprintf "curl -s %s 2>/dev/null" url in
    match exec_command cmd with
    | Some json_str ->
        (* Parse JSON to extract version *)
        let json = Yojson.Safe.from_string json_str in
        let version = Yojson.Safe.Util.member "version" json
                     |> Yojson.Safe.Util.to_string in
        Some version
    | None -> None
  with
  | _ -> None

(** Get version with fallbacks: npm -> curl -> fallback *)
let get_package_version ?(use_fallback_first=false) package_name =
  if use_fallback_first then
    get_fallback_version package_name
  else
    match fetch_latest_version_npm package_name with
    | Some version -> version
    | None ->
        match fetch_latest_version_curl package_name with
        | Some version -> version
        | None ->
            printf "Warning: Could not fetch latest version for %s, using fallback\n" package_name;
            get_fallback_version package_name

(** Get versions for multiple packages *)
let get_package_versions ?(use_fallback_first=false) package_names =
  List.map (fun name ->
    (name, get_package_version ~use_fallback_first name)
  ) package_names

(** Common TypeScript dev dependencies *)
let typescript_dev_dependencies = [
  "typescript";
  "@types/node";
  "jest";
  "@types/jest";
]

(** Get TypeScript package versions *)
let get_typescript_versions ?(use_fallback_first=false) () =
  get_package_versions ~use_fallback_first typescript_dev_dependencies

(** Validate that a version string looks reasonable *)
let is_valid_version version =
  let version_regex = Str.regexp "^[0-9]+\\.[0-9]+\\.[0-9]+" in
  Str.string_match version_regex version 0

(** Validate generated package versions *)
let validate_package_versions versions =
  let invalid_versions = List.filter (fun (_, version) ->
    not (is_valid_version version)
  ) versions in
  match invalid_versions with
  | [] ->
    printf "✅ All package versions are valid\n";
    true
  | invalid ->
    printf "❌ Invalid versions found:\n";
    List.iter (fun (name, version) ->
      printf "  - %s: %s\n" name version
    ) invalid;
    false