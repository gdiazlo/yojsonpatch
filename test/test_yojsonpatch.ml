open! Core
module Jsonpatch = Yojsonpatch.Jsonpatch
module Jsonpointer = Yojsonpatch.Jsonpointer

let yojson = Alcotest.testable Yojson.Safe.pp Yojson.Safe.equal

let string_or_null (v : Yojson.Safe.t) =
  match v with
  | `String s -> s
  | `Null -> "null"
  | _ -> failwith "Invalid JSON value"
;;

let exec_test test_case =
  let open Yojson.Safe.Util in
  let comment = test_case |> member "comment" |> string_or_null in
  try
    let patch = test_case |> member "patch" |> Jsonpatch.from_json in
    let doc = test_case |> member "doc" in
    let expected = test_case |> member "expected" in
    let patched_doc = Jsonpatch.apply doc patch in
    Alcotest.(check yojson) comment expected patched_doc
  with
  | Jsonpatch.Operation_error msg ->
    (match test_case |> member "error" with
     | `Null -> Alcotest.fail msg
     | err -> Alcotest.(check string) comment (err |> to_string) msg)
  | Jsonpatch.Operation_not_implemented _ ->
    Alcotest.fail "Operation not implemented exception!"
  | Jsonpatch.Invalid_patch msg ->
    (match test_case |> member "error" with
     | `Null -> Alcotest.fail msg
     | err -> Alcotest.(check string) comment (err |> to_string) msg)
  | Jsonpatch.Invalid_operation msg ->
    (match test_case |> member "error" with
     | `Null -> Alcotest.fail msg
     | err -> Alcotest.(check string) comment (err |> to_string) msg)
  | Jsonpointer.Invalid_pointer msg ->
    (match test_case |> member "error" with
     | `Null -> Alcotest.fail msg
     | err -> Alcotest.(check string) comment (err |> to_string) msg)
  | Yojson.Json_error msg -> Alcotest.fail msg
;;

let gen_tests filename =
  let open Yojson.Safe in
  try
    let json = from_file filename in
    match json with
    | `List test_cases ->
      List.filter test_cases ~f:(fun e ->
        match e with
        | `Assoc l ->
          (match List.Assoc.find l ~equal:String.equal "skip" with
           | Some _ -> false
           | None -> true)
        | _ -> false)
      |> List.map ~f:(fun case ->
        let comment = case |> Util.member "comment" |> pretty_to_string in
        Alcotest.test_case comment `Quick (fun () -> exec_test case))
    | _ -> failwith "Invalid JSON format: Expected a JSON array"
  with
  | Sys_error msg -> failwith ("Error: " ^ msg)
  | Yojson.Json_error msg -> failwith ("JSON parsing error: " ^ msg)
  | Failure msg -> failwith ("Test case processing error: " ^ msg)
;;

let all_tests = gen_tests "tests.json"
let rfc_tests = gen_tests "spec_tests.json"

(* Main function to run the test cases from the specified JSON file *)
let () =
  Alcotest.run "JSON patch test suite" [ "RFC_tests", rfc_tests; "All_tests", all_tests ]
;;
