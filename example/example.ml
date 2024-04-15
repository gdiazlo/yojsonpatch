open Yojsonpatch
open Jsonpointer
open Jsonpatch

(** Define a json document, it must be converted to a Yojson.Safe.t *)
let doc_str = {|
{
  "title": "UNIX: A History and a Memoir"
}
|}

(** We can create a patch from its JSON form as a string using the
    [Jsonpatch.from_string str] function *)
let patch_str =
  {|
[
  {"op": "add", "path": "/author", "value": "Brian W. Kernighan"},
  {"op": "add", "path": "/published", "value": 2020}
]
|}
;;

(** We can also create a patch directly using the type constructors
    defined in the library *)
let patch_obj =
  [ Add (pointer "/publisher", `String "Kindle Direct Publishing")
  ; Add (pointer "/stars", `Int 5)
  ; Add (pointer "/purchased", `String "2019-10-22")
  ]
;;

let () =
  let patch = Jsonpatch.from_string patch_str in
  let doc = Yojson.Safe.from_string doc_str in
  let patched_doc = Jsonpatch.apply doc patch in
  let new_patched_doc = Jsonpatch.apply patched_doc patch_obj in
  Format.printf
    "Original doc:\n%s\nPatched doc:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string new_patched_doc)
;;
