let test_fallback_typescript () =
  Alcotest.(check string) "typescript"
    "5.9.2" (Utils.Version_fetcher.get_fallback_version "typescript")

let test_fallback_types_node () =
  Alcotest.(check string) "@types/node"
    "24.5.2" (Utils.Version_fetcher.get_fallback_version "@types/node")

let test_fallback_jest () =
  Alcotest.(check string) "jest"
    "30.1.3" (Utils.Version_fetcher.get_fallback_version "jest")

let test_fallback_types_jest () =
  Alcotest.(check string) "@types/jest"
    "30.0.0" (Utils.Version_fetcher.get_fallback_version "@types/jest")

let test_fallback_unknown_returns_latest () =
  Alcotest.(check string) "unknown"
    "latest" (Utils.Version_fetcher.get_fallback_version "unknown-pkg")

let test_get_package_version_fallback_first () =
  let v = Utils.Version_fetcher.get_package_version ~use_fallback_first:true "typescript" in
  Alcotest.(check string) "fallback first" "5.9.2" v

let test_get_package_versions_batch () =
  let vs = Utils.Version_fetcher.get_package_versions ~use_fallback_first:true
    ["typescript"; "@types/node"] in
  Alcotest.(check int) "count" 2 (List.length vs);
  Alcotest.(check string) "typescript" "5.9.2" (List.assoc "typescript" vs);
  Alcotest.(check string) "@types/node" "24.5.2" (List.assoc "@types/node" vs)

let test_get_typescript_versions_four_packages () =
  let vs = Utils.Version_fetcher.get_typescript_versions ~use_fallback_first:true () in
  Alcotest.(check int) "count" 4 (List.length vs);
  let names = List.map fst vs in
  Alcotest.(check bool) "has typescript" true (List.mem "typescript" names);
  Alcotest.(check bool) "has @types/node" true (List.mem "@types/node" names);
  Alcotest.(check bool) "has jest" true (List.mem "jest" names);
  Alcotest.(check bool) "has @types/jest" true (List.mem "@types/jest" names)

let test_is_valid_version_accepts_semver () =
  Alcotest.(check bool) "1.2.3" true (Utils.Version_fetcher.is_valid_version "1.2.3");
  Alcotest.(check bool) "0.0.0" true (Utils.Version_fetcher.is_valid_version "0.0.0");
  Alcotest.(check bool) "12.345.6789" true (Utils.Version_fetcher.is_valid_version "12.345.6789")

let test_is_valid_version_rejects_invalid () =
  Alcotest.(check bool) "latest" false (Utils.Version_fetcher.is_valid_version "latest");
  Alcotest.(check bool) "empty" false (Utils.Version_fetcher.is_valid_version "");
  Alcotest.(check bool) "abc" false (Utils.Version_fetcher.is_valid_version "abc");
  Alcotest.(check bool) "1.2" false (Utils.Version_fetcher.is_valid_version "1.2")

let test_is_valid_version_accepts_prerelease () =
  (* regex matches prefix ^[0-9]+\.[0-9]+\.[0-9]+ so prerelease suffix is fine *)
  Alcotest.(check bool) "1.0.0-beta.1" true
    (Utils.Version_fetcher.is_valid_version "1.0.0-beta.1")

let test_validate_all_valid () =
  Alcotest.(check bool) "all valid" true
    (Utils.Version_fetcher.validate_package_versions [("a", "1.0.0"); ("b", "2.3.4")])

let test_validate_some_invalid () =
  Alcotest.(check bool) "has invalid" false
    (Utils.Version_fetcher.validate_package_versions [("good", "1.0.0"); ("bad", "latest")])

let test_validate_empty_list () =
  Alcotest.(check bool) "empty is valid" true
    (Utils.Version_fetcher.validate_package_versions [])

let tests = [
  Alcotest.test_case "fallback typescript" `Quick test_fallback_typescript;
  Alcotest.test_case "fallback @types/node" `Quick test_fallback_types_node;
  Alcotest.test_case "fallback jest" `Quick test_fallback_jest;
  Alcotest.test_case "fallback @types/jest" `Quick test_fallback_types_jest;
  Alcotest.test_case "fallback unknown returns latest" `Quick test_fallback_unknown_returns_latest;
  Alcotest.test_case "get_package_version fallback first" `Quick test_get_package_version_fallback_first;
  Alcotest.test_case "get_package_versions batch" `Quick test_get_package_versions_batch;
  Alcotest.test_case "get_typescript_versions returns 4" `Quick test_get_typescript_versions_four_packages;
  Alcotest.test_case "is_valid_version accepts semver" `Quick test_is_valid_version_accepts_semver;
  Alcotest.test_case "is_valid_version rejects invalid" `Quick test_is_valid_version_rejects_invalid;
  Alcotest.test_case "is_valid_version accepts prerelease" `Quick test_is_valid_version_accepts_prerelease;
  Alcotest.test_case "validate all valid" `Quick test_validate_all_valid;
  Alcotest.test_case "validate some invalid" `Quick test_validate_some_invalid;
  Alcotest.test_case "validate empty list" `Quick test_validate_empty_list;
]
