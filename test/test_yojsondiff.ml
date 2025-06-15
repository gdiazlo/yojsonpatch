module Jsondiff = Yojsonpatch.Jsondiff
module Jsonpatch = Yojsonpatch.Jsonpatch
module Jsonpointer = Yojsonpatch.Jsonpointer

let yojson = Alcotest.testable Yojson.Safe.pp Yojson.Safe.equal
let patch_testable = Alcotest.testable Jsonpatch.pp ( = )

(* Helper function to create JSON values from strings *)
let json_of_string s = Yojson.Safe.from_string s

(* Helper function to apply a patch and verify it produces the expected result *)
let verify_diff_patch original target =
  let patch = Jsondiff.diff original target in
  let result = Jsonpatch.apply original patch in
  Alcotest.(check yojson) "diff patch should transform original to target" target result
;;

(* Test cases for primitive value changes *)
let test_primitive_diff () =
  let original = `String "hello" in
  let target = `String "world" in
  verify_diff_patch original target
;;

let test_number_diff () =
  let original = `Int 42 in
  let target = `Int 100 in
  verify_diff_patch original target
;;

let test_bool_diff () =
  let original = `Bool true in
  let target = `Bool false in
  verify_diff_patch original target
;;

let test_null_to_value () =
  let original = `Null in
  let target = `String "hello" in
  verify_diff_patch original target
;;

let test_value_to_null () =
  let original = `String "hello" in
  let target = `Null in
  verify_diff_patch original target
;;

(* Test cases for identical values *)
(* Test cases for identical values *)
let test_identical_primitives () =
  let original = `String "same" in
  let target = `String "same" in
  let patch = Jsondiff.diff original target in
  Alcotest.(check patch_testable) "identical values should produce empty patch" [] patch
;;

let test_identical_objects () =
  let json = json_of_string {|{"name": "John", "age": 30}|} in
  let patch = Jsondiff.diff json json in
  Alcotest.(check patch_testable) "identical objects should produce empty patch" [] patch
;;

(* Test cases for object differences *)
let test_object_add_property () =
  let original = json_of_string {|{"name": "John"}|} in
  let target = json_of_string {|{"name": "John", "age": 30}|} in
  verify_diff_patch original target
;;

let test_object_remove_property () =
  let original = json_of_string {|{"name": "John", "age": 30}|} in
  let target = json_of_string {|{"name": "John"}|} in
  verify_diff_patch original target
;;

let test_object_replace_property () =
  let original = json_of_string {|{"name": "John", "age": 30}|} in
  let target = json_of_string {|{"name": "Jane", "age": 30}|} in
  verify_diff_patch original target
;;

let test_object_complex_changes () =
  let original = json_of_string {|{"name": "John", "age": 30, "city": "NYC"}|} in
  let target = json_of_string {|{"name": "Jane", "age": 25, "country": "USA"}|} in
  verify_diff_patch original target
;;

let test_nested_object_changes () =
  let original = json_of_string {|{"user": {"name": "John", "details": {"age": 30}}}|} in
  let target =
    json_of_string {|{"user": {"name": "Jane", "details": {"age": 25, "city": "NYC"}}}|}
  in
  verify_diff_patch original target
;;

(* Test cases for array differences *)
let test_array_add_element () =
  let original = json_of_string {|[1, 2, 3]|} in
  let target = json_of_string {|[1, 2, 3, 4]|} in
  verify_diff_patch original target
;;

let test_array_remove_element () =
  let original = json_of_string {|[1, 2, 3, 4]|} in
  let target = json_of_string {|[1, 2, 3]|} in
  verify_diff_patch original target
;;

let test_array_replace_element () =
  let original = json_of_string {|[1, 2, 3]|} in
  let target = json_of_string {|[1, 5, 3]|} in
  verify_diff_patch original target
;;

let test_array_multiple_changes () =
  let original = json_of_string {|[1, 2, 3, 4, 5]|} in
  let target = json_of_string {|[1, 10, 3, 6]|} in
  verify_diff_patch original target
;;

let test_empty_arrays () =
  let original = json_of_string {|[]|} in
  let target = json_of_string {|[1, 2, 3]|} in
  verify_diff_patch original target
;;

let test_array_to_empty () =
  let original = json_of_string {|[1, 2, 3]|} in
  let target = json_of_string {|[]|} in
  verify_diff_patch original target
;;

let test_nested_array_changes () =
  let original =
    json_of_string {|{"data": [{"id": 1, "name": "A"}, {"id": 2, "name": "B"}]}|}
  in
  let target =
    json_of_string {|{"data": [{"id": 1, "name": "X"}, {"id": 3, "name": "C"}]}|}
  in
  verify_diff_patch original target
;;

(* Test cases for type changes *)
let test_object_to_array () =
  let original = json_of_string {|{"key": "value"}|} in
  let target = json_of_string {|[1, 2, 3]|} in
  verify_diff_patch original target
;;

let test_array_to_object () =
  let original = json_of_string {|[1, 2, 3]|} in
  let target = json_of_string {|{"key": "value"}|} in
  verify_diff_patch original target
;;

let test_primitive_to_object () =
  let original = json_of_string {|"hello"|} in
  let target = json_of_string {|{"greeting": "hello"}|} in
  verify_diff_patch original target
;;

let test_object_to_primitive () =
  let original = json_of_string {|{"greeting": "hello"}|} in
  let target = json_of_string {|"hello"|} in
  verify_diff_patch original target
;;

(* Test cases for complex nested structures *)
let test_complex_nested_diff () =
  let original =
    json_of_string
      {|{
    "users": [
      {"id": 1, "name": "John", "settings": {"theme": "dark"}},
      {"id": 2, "name": "Jane", "settings": {"theme": "light"}}
    ],
    "config": {"version": "1.0", "features": ["auth", "logging"]}
  }|}
  in
  let target =
    json_of_string
      {|{
    "users": [
      {"id": 1, "name": "Johnny", "settings": {"theme": "dark", "language": "en"}},
      {"id": 3, "name": "Bob", "settings": {"theme": "auto"}}
    ],
    "config": {"version": "1.1", "features": ["auth", "metrics"], "debug": true}
  }|}
  in
  verify_diff_patch original target
;;

(* Edge cases *)
let test_empty_objects () =
  let original = json_of_string {|{}|} in
  let target = json_of_string {|{"key": "value"}|} in
  verify_diff_patch original target
;;

let test_object_to_empty () =
  let original = json_of_string {|{"key": "value"}|} in
  let target = json_of_string {|{}|} in
  verify_diff_patch original target
;;

let test_deeply_nested () =
  let original = json_of_string {|{"a": {"b": {"c": {"d": 1}}}}|} in
  let target = json_of_string {|{"a": {"b": {"c": {"d": 2, "e": 3}}}}|} in
  verify_diff_patch original target
;;

(* Test suite definition *)
let primitive_tests =
  [ Alcotest.test_case "primitive string diff" `Quick test_primitive_diff
  ; Alcotest.test_case "number diff" `Quick test_number_diff
  ; Alcotest.test_case "boolean diff" `Quick test_bool_diff
  ; Alcotest.test_case "null to value" `Quick test_null_to_value
  ; Alcotest.test_case "value to null" `Quick test_value_to_null
  ]
;;

let identity_tests =
  [ Alcotest.test_case "identical primitives" `Quick test_identical_primitives
  ; Alcotest.test_case "identical objects" `Quick test_identical_objects
  ]
;;

let object_tests =
  [ Alcotest.test_case "object add property" `Quick test_object_add_property
  ; Alcotest.test_case "object remove property" `Quick test_object_remove_property
  ; Alcotest.test_case "object replace property" `Quick test_object_replace_property
  ; Alcotest.test_case "object complex changes" `Quick test_object_complex_changes
  ; Alcotest.test_case "nested object changes" `Quick test_nested_object_changes
  ]
;;

let array_tests =
  [ Alcotest.test_case "array add element" `Quick test_array_add_element
  ; Alcotest.test_case "array remove element" `Quick test_array_remove_element
  ; Alcotest.test_case "array replace element" `Quick test_array_replace_element
  ; Alcotest.test_case "array multiple changes" `Quick test_array_multiple_changes
  ; Alcotest.test_case "empty arrays" `Quick test_empty_arrays
  ; Alcotest.test_case "array to empty" `Quick test_array_to_empty
  ; Alcotest.test_case "nested array changes" `Quick test_nested_array_changes
  ]
;;

let type_change_tests =
  [ Alcotest.test_case "object to array" `Quick test_object_to_array
  ; Alcotest.test_case "array to object" `Quick test_array_to_object
  ; Alcotest.test_case "primitive to object" `Quick test_primitive_to_object
  ; Alcotest.test_case "object to primitive" `Quick test_object_to_primitive
  ]
;;

let complex_tests =
  [ Alcotest.test_case "complex nested diff" `Quick test_complex_nested_diff ]
;;

let edge_case_tests =
  [ Alcotest.test_case "empty objects" `Quick test_empty_objects
  ; Alcotest.test_case "object to empty" `Quick test_object_to_empty
  ; Alcotest.test_case "deeply nested" `Quick test_deeply_nested
  ]
;;

let () =
  Alcotest.run
    "JSON diff test suite"
    [ "primitive_diffs", primitive_tests
    ; "identity_tests", identity_tests
    ; "object_diffs", object_tests
    ; "array_diffs", array_tests
    ; "type_changes", type_change_tests
    ; "complex_cases", complex_tests
    ; "edge_cases", edge_case_tests
    ]
;;
