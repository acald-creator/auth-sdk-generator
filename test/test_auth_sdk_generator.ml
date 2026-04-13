let () =
  Alcotest.run "auth-sdk-generator" [
    ("AST Helpers", Test_ast.tests);
    ("Parser", Test_parser.tests);
    ("Version Fetcher", Test_version_fetcher.tests);
    ("TypeScript Generator", Test_ts_generator.tests);
    ("Python Generator", Test_py_generator.tests);
    ("Validators", Test_validators.tests);
    ("PKCE Refactor", Test_pkce_refactor.tests);
  ]
