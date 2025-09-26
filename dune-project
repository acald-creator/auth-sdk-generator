(lang dune 3.20)

(name auth-sdk-generator)

(generate_opam_files true)

(source
 (github acald-creator/auth-sdk-generator))

(authors "acald-creator")

(maintainers "acald-creator")

(license MIT)

(documentation https://github.com/acald-creator/auth-sdk-generator)

(package
 (name auth-sdk-generator)
 (version 1.0.0-beta.1)
 (synopsis "OCaml-based polyglot authentication SDK generator")
 (description "Generate type-safe authentication SDKs for multiple languages from custom DSL specifications. Supports OAuth 2.0, OAuth 3.0/GNAP, and PKCE.")
 (depends
  ocaml
  dune
  core
  yojson
  menhir
  sedlex
  ppx_deriving
  alcotest
  ounit2
  js_of_ocaml
  js_of_ocaml-ppx)
 (tags
  ("oauth" "authentication" "sdk" "code-generation" "ocaml" "typescript")))
