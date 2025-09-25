open Ast.Auth_types

exception Parse_error of string

(** Simple line-based parser for prototype *)
let parse_simple_dsl content =
  let lines =
    content
    |> String.split_on_char '\n'
    |> List.map String.trim
    |> List.filter (fun s -> s <> "" && not (String.starts_with ~prefix:"#" s))
  in

  let rec parse_lines acc = function
    | [] -> acc
    | line :: rest ->
        if String.contains line '=' then
          let idx = String.index line '=' in
          let key = String.sub line 0 idx |> String.trim in
          let value = String.sub line (idx + 1) (String.length line - idx - 1) |> String.trim in
          (* Remove quotes if present *)
          let value = if String.length value >= 2 && String.get value 0 = '"' && String.get value (String.length value - 1) = '"'
                     then String.sub value 1 (String.length value - 2)
                     else value in
          parse_lines ((key, value) :: acc) rest
        else
          parse_lines acc rest
  in

  let key_values = parse_lines [] lines in

  (* Extract values with defaults *)
  let get_value key default =
    match List.assoc_opt key key_values with
    | Some v -> v
    | None -> default
  in

  let get_list key =
    match List.assoc_opt key key_values with
    | Some v -> String.split_on_char ',' v |> List.map String.trim
    | None -> []
  in

  (* Build specification *)
  let name = get_value "name" "prototype" in
  let client_id = get_value "client_id" "" in
  let auth_url = get_value "authorize_url" "https://accounts.google.com/o/oauth2/v2/auth" in
  let token_url = get_value "token_url" "https://oauth2.googleapis.com/token" in
  let scopes = get_list "scopes" in

  if String.equal client_id "" then
    raise (Parse_error "client_id is required");

  let provider = create_provider "default" client_id auth_url token_url scopes in
  create_oauth2_spec name [provider]

(** Parse from file *)
let parse_file filename =
  let ic = open_in filename in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  parse_simple_dsl content