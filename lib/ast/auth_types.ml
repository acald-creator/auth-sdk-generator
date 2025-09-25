(** Minimal AST for prototype - focus on OAuth 2.0 + PKCE *)

type auth_spec = {
  name: string;
  protocol: protocol;
  providers: provider list;
}
[@@deriving show]

and protocol =
  | OAuth2 of oauth2_config
[@@deriving show]

and oauth2_config = {
  flows: oauth2_flow list;
  pkce: bool;
  state_required: bool;
}
[@@deriving show]

and oauth2_flow =
  | AuthorizationCode
  | ClientCredentials
[@@deriving show]

and provider = {
  name: string;
  client_id: string;
  client_secret: string option;
  authorize_url: string;
  token_url: string;
  scopes: string list;
  extra_params: (string * string) list;
}
[@@deriving show]

(** Helper functions *)
let create_oauth2_spec name providers =
  {
    name;
    protocol = OAuth2 { flows = [AuthorizationCode]; pkce = true; state_required = true };
    providers;
  }

let create_provider name client_id auth_url token_url scopes =
  {
    name;
    client_id;
    client_secret = None;
    authorize_url = auth_url;
    token_url = token_url;
    scopes;
    extra_params = [];
  }