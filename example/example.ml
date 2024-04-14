open Yojsonpatch

let doc_str = {|
{
  "title": "UNIX: A History and a Memoir"
}
|}

let patch_str =
  {|
[
  {"op": "add", "path": "/author", "value": "Brian W. Kernighan"},
  {"op": "add", "path": "/publication", "value": 2020}
]
|}
;;

let () =
  let patch = Jsonpatch.from_string patch_str in
  let doc = Yojson.Safe.from_string doc_str in
  let patched_doc = Jsonpatch.apply doc patch in
  Format.printf
    " Original doc:\n%s\nPatched doc:\n%s\n"
    (Yojson.Safe.pretty_to_string doc)
    (Yojson.Safe.pretty_to_string patched_doc)
;;
