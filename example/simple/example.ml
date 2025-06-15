open Yojsonpatch
open Jsonpatch
(** Define a json document, it must be converted to a Yojson.Safe.t *)
let doc_str =
  {|
{
  "title": "UNIX: A History and a Memoir"
}
|}
;;

(** We can create a patch from its JSON form as a string using the
    [Jsonpatch.from_string str] function or using convenience
    functions like add below *)
let patch =
  [ add "/author" {|"Brian W. Kernighan"|}
  ; add "/published" "2020"
  ; add "/publisher" {|"Kindle Direct Publishing"|}
  ; add "/stars" "5"
  ; add "/purchased" {|"2019-10-22"|}
  ]
;;

let () =
  let doc = Yojson.Safe.from_string doc_str in
  let patched_doc = Jsonpatch.apply doc patch in
  let gen_patch = Jsondiff.diff doc patched_doc in
  Format.printf
    "Original doc:\n%s\nPatch:\n%s\nPatched doc:\n%s\nGenerated patch:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string (to_json patch))
    (Yojson.Safe.pretty_to_string patched_doc)
    (Yojson.Safe.pretty_to_string (to_json gen_patch))
;;
