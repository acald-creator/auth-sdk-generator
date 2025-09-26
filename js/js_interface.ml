open Js_of_ocaml

(* JavaScript object type for auth spec *)
class type auth_spec_js = object
  method name : Js.js_string Js.t Js.readonly_prop
  method clientId : Js.js_string Js.t Js.readonly_prop
  method clientSecret : Js.js_string Js.t Js.opt Js.readonly_prop
  method authorizeUrl : Js.js_string Js.t Js.readonly_prop
  method tokenUrl : Js.js_string Js.t Js.readonly_prop
  method redirectUri : Js.js_string Js.t Js.readonly_prop
  method scopes : Js.js_string Js.t Js.js_array Js.t Js.readonly_prop
end

(* Convert JavaScript object to OCaml auth_spec *)
let auth_spec_of_js (js_spec : auth_spec_js Js.t) : Ast.Auth_types.auth_spec =
  let name = Js.to_string js_spec##.name in
  let client_id = Js.to_string js_spec##.clientId in
  let client_secret = Js.Opt.case js_spec##.clientSecret (fun () -> None) (fun s -> Some (Js.to_string s)) in
  let authorize_url = Js.to_string js_spec##.authorizeUrl in
  let token_url = Js.to_string js_spec##.tokenUrl in
  let scopes = js_spec##.scopes |> Js.to_array |> Array.to_list |> List.map Js.to_string in

  let provider = {
    Ast.Auth_types.name = name;
    client_id = client_id;
    client_secret = client_secret;
    authorize_url = authorize_url;
    token_url = token_url;
    scopes = scopes;
    extra_params = [];
  } in

  Ast.Auth_types.create_oauth2_spec name [provider]

(* Generate TypeScript SDK *)
let generate_typescript_sdk_js (js_spec : auth_spec_js Js.t) (output_dir : Js.js_string Js.t) : unit =
  let spec = auth_spec_of_js js_spec in
  let output_dir_string = Js.to_string output_dir in
  Typescript_generator.Ts_generator.generate_typescript_sdk ~use_fallback_versions:false spec output_dir_string

(* Generate Python SDK *)
let generate_python_sdk_js (js_spec : auth_spec_js Js.t) (output_dir : Js.js_string Js.t) : unit =
  let spec = auth_spec_of_js js_spec in
  let output_dir_string = Js.to_string output_dir in
  Python_generator.Py_generator.generate_python_sdk spec output_dir_string

(* Export functions to JavaScript *)
let () =
  Js.export "AuthSDKGenerator" (object%js
    method generateTypeScript spec outputDir = generate_typescript_sdk_js spec outputDir
    method generatePython spec outputDir = generate_python_sdk_js spec outputDir
  end)